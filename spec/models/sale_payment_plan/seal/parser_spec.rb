# frozen_string_literal: true

require "rails_helper"

RSpec.describe SalePaymentPlan::Seal::Parser do
  it "builds a deposit projection from an authoritative percentage adjustment" do
    result = described_class.parse(
      subscription(max_cycles: 1, item_amount: "300.00", delivery_price: "20.00"),
      selling_plans_by_id: {
        "plan-1" => selling_plan(adjustment_value: "70", max_cycles: 1)
      }
    )

    expect(result[:attributes]).to include(
      provider: "seal",
      external_id: "1",
      external_origin_order_id: "100",
      kind: "deposit",
      expected_parts: 1,
      deposit_percent: BigDecimal("30"),
      projected_total: BigDecimal("1020"),
      currency: "EUR"
    )
    expect(result[:parts]).to contain_exactly(
      hash_including(sequence: 1, external_order_id: "100", amount: BigDecimal("300"))
    )
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
      }
    )

    expect(result[:attributes]).to include(
      kind: "installments",
      expected_parts: 4,
      projected_total: BigDecimal("1020"),
      next_due_at: DateTime.parse("2026-03-01T10:00:00Z")
    )
    expect(result[:parts].map { |part| part.values_at(:sequence, :external_order_id) }).to eq(
      [[1, "100"], [2, "101"], [3, "102"], [4, nil]]
    )
  end

  it "omits projections when provider pricing is ambiguous" do
    result = described_class.parse(
      subscription(max_cycles: 4, item_amount: "250.00", delivery_price: "20.00"),
      selling_plans_by_id: {
        "plan-1" => selling_plan(adjustment_type: "FIXED_AMOUNT", adjustment_value: "75", max_cycles: 4)
      }
    )

    expect(result[:attributes]).to include(kind: "installments", projected_total: nil)
  end

  it "omits projections when any subscription item lacks authoritative pricing" do
    data = subscription(max_cycles: 4, item_amount: "250.00", delivery_price: "20.00")
    data["items"] << data["items"].first.merge(
      "id" => 11,
      "selling_plan_id" => "missing-plan"
    )

    result = described_class.parse(
      data,
      selling_plans_by_id: {
        "plan-1" => selling_plan(adjustment_value: "75", max_cycles: 4)
      }
    )

    expect(result[:attributes]).to include(kind: "installments", projected_total: nil)
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

  def selling_plan(adjustment_type: "PERCENTAGE", adjustment_value:, max_cycles:)
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
