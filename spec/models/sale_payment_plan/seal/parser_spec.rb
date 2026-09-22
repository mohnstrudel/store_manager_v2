# frozen_string_literal: true

require "rails_helper"

RSpec.describe SalePaymentPlan::Seal::Parser do
  let(:origin_date) { Date.new(2024, 1, 1) }

  before do
    create(:exchange_rate, date: origin_date, currency: "USD", rate: BigDecimal("1.0000"))
  end

  it "builds a deposit projection from an authoritative percentage adjustment" do
    result = described_class.parse(
      subscription(max_cycles: 1, item_amount: "300.00", delivery_price: "20.00"),
      selling_plans_by_id: {
        "plan-1" => selling_plan(adjustment_value: "70", max_cycles: 1)
      },
      origin_date:
    )

    expect(result[:attributes]).to include(
      provider: "seal",
      external_id: "1",
      external_origin_order_id: "100",
      kind: "deposit",
      expected_parts: 1,
      deposit_percent: BigDecimal(30),
      projected_total: BigDecimal(1020)
    )
    expect(result[:attributes]).not_to have_key(:currency)
    expect(result[:parts]).to contain_exactly(
      hash_including(sequence: 1, external_order_id: "100", amount: BigDecimal(300))
    )
  end

  it "converts the projected total and part amounts from the recorded source currency using the linked origin's external date" do
    conversion_date = Date.new(2026, 8, 21)
    create(:exchange_rate, date: conversion_date, currency: "USD", rate: BigDecimal("1.1250"))

    result = described_class.parse(
      subscription(max_cycles: 4, item_amount: "250.00", delivery_price: "20.00"),
      selling_plans_by_id: {
        "plan-1" => selling_plan(adjustment_value: "75", max_cycles: 4)
      },
      origin_date: conversion_date
    )

    expect(result[:attributes][:projected_total]).to eq(BigDecimal("1147.50"))
    expect(result[:parts].first[:amount]).to eq(BigDecimal("281.25"))
  end

  it "defers monetary reconciliation and persists no foreign amount as USD when the origin date is not yet resolvable" do
    result = described_class.parse(
      subscription(max_cycles: 4, item_amount: "250.00", delivery_price: "20.00"),
      selling_plans_by_id: {
        "plan-1" => selling_plan(adjustment_value: "75", max_cycles: 4)
      }
    )

    expect(result[:attributes][:projected_total]).to be_nil
    expect(result[:parts]).to all(include(amount: nil))
  end

  it "deduplicates completed retries and fills the remaining contractual parts" do
    data = subscription(max_cycles: 4, item_amount: "250.00", delivery_price: "20.00")
    data["billing_attempts"] = [
      attempt(id: 1, order_id: "101", completed_at: "2026-01-01T10:00:00Z", status: "completed"),
      attempt(id: 2, order_id: "101", completed_at: "2026-01-01T10:05:00Z", status: "completed"),
      attempt(id: 3, order_id: "102", completed_at: "2026-02-01T10:00:00Z", status: "completed"),
      attempt(id: 4, date: "2026-03-01T10:00:00Z"),
      attempt(id: 5, date: "2026-03-02T10:00:00Z", status: "failed")
    ]

    result = described_class.parse(
      data,
      selling_plans_by_id: {
        "plan-1" => selling_plan(adjustment_value: "75", max_cycles: 4)
      },
      origin_date:
    )

    expect(result[:attributes]).to include(
      kind: "installments",
      expected_parts: 4,
      projected_total: BigDecimal(1020),
      next_due_at: DateTime.parse("2026-03-01T10:00:00Z")
    )
    expect(result[:parts].map { |part| part.values_at(:sequence, :external_order_id) }).to eq(
      [[1, "100"], [2, "101"], [3, "102"], [4, nil]]
    )
  end

  it "eight-cycle installment uses recurring amount × subscription cycles" do
    rate_date = Date.new(2024, 2, 1)
    create(:exchange_rate, date: rate_date, currency: "USD", rate: BigDecimal("1.1448"))

    result = described_class.parse(
      subscription(max_cycles: 8, item_amount: "56.25", delivery_price: "20.00"),
      selling_plans_by_id: {
        "plan-1" => selling_plan(adjustment_value: "75", max_cycles: 8)
      },
      origin_date: rate_date
    )

    expect(result[:attributes]).to include(kind: "installments", projected_total: BigDecimal("538.06"))
  end

  it "projects full installment merchandise even when the selling plan's adjustment isn't a percentage" do
    result = described_class.parse(
      subscription(max_cycles: 4, item_amount: "250.00", delivery_price: "20.00"),
      selling_plans_by_id: {
        "plan-1" => selling_plan(adjustment_type: "FIXED_AMOUNT", adjustment_value: "75", max_cycles: 4)
      },
      origin_date:
    )

    expect(result[:attributes]).to include(kind: "installments", projected_total: BigDecimal(1020))
  end

  it "omits an installment projection when any item is ineligible" do
    plans = {"plan-1" => selling_plan(adjustment_value: "75", max_cycles: 4)}

    ["", "not-a-number"].each do |final_amount|
      data = subscription(max_cycles: 4, item_amount: final_amount, delivery_price: "20.00")
      result = described_class.parse(data, selling_plans_by_id: plans, origin_date:)
      expect(result[:attributes][:projected_total]).to be_nil
    end

    one_time = subscription(max_cycles: 4, item_amount: "250.00", delivery_price: "20.00")
    one_time["items"].first["is_one_time_item"] = 1
    result = described_class.parse(one_time, selling_plans_by_id: plans, origin_date:)
    expect(result[:attributes][:projected_total]).to be_nil

    cycle_discounted = subscription(max_cycles: 4, item_amount: "250.00", delivery_price: "20.00")
    cycle_discounted["items"].first["cycle_discounts"] = [{"discount_amount" => "10"}]
    result = described_class.parse(cycle_discounted, selling_plans_by_id: plans, origin_date:)
    expect(result[:attributes][:projected_total]).to be_nil
  end

  it "omits a deposit projection without one uniform positive percentage" do
    data = subscription(max_cycles: 1, item_amount: "300.00", delivery_price: "20.00")
    data["items"] << data["items"].first.merge("id" => 11, "selling_plan_id" => "plan-2")

    result = described_class.parse(
      data,
      selling_plans_by_id: {
        "plan-1" => selling_plan(adjustment_value: "70", max_cycles: 1),
        "plan-2" => selling_plan(adjustment_value: "60", max_cycles: 1)
      },
      origin_date:
    )

    expect(result[:attributes][:projected_total]).to be_nil
  end

  it "omits a projection when required delivery money is missing or malformed" do
    plans = {"plan-1" => selling_plan(adjustment_value: "75", max_cycles: 4)}

    ["", "TBD"].each do |delivery_price|
      result = described_class.parse(
        subscription(max_cycles: 4, item_amount: "250.00", delivery_price:),
        selling_plans_by_id: plans,
        origin_date:
      )

      expect(result[:attributes][:projected_total]).to be_nil
    end
  end

  def subscription(max_cycles:, item_amount:, delivery_price:)
    {
      "id" => 1,
      "order_id" => "100",
      "status" => "ACTIVE",
      "billing_max_cycles" => max_cycles,
      "currency" => "EUR",
      "delivery_price" => delivery_price,
      "items" => [
        {
          "id" => 10,
          "selling_plan_id" => "plan-1",
          "final_amount" => item_amount,
          "is_one_time_item" => 0,
          "cycle_discounts" => []
        }
      ],
      "billing_attempts" => []
    }
  end

  def selling_plan(adjustment_value:, max_cycles:, adjustment_type: "PERCENTAGE")
    {
      "selling_plan_id" => "plan-1",
      "pricing_policy_fixed_adjustment_type" => adjustment_type,
      "pricing_policy_fixed_adjustment_value" => adjustment_value,
      "billing_max_cycles" => max_cycles
    }
  end

  def attempt(id:, order_id: "", completed_at: "", date: "", status: "")
    {
      "id" => id,
      "order_id" => order_id,
      "completed_at" => completed_at,
      "date" => date,
      "status" => status
    }
  end
end
