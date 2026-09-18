# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seal::SyncPaymentPlansJob do
  let(:client) { instance_double(Seal::Api::Client) }
  let(:subscription) do
    {
      "id" => 1,
      "order_id" => "100",
      "status" => "ACTIVE",
      "billing_max_cycles" => 4,
      "currency" => "EUR",
      "delivery_price" => "20.00",
      "items" => [
        {
          "id" => 10,
          "selling_plan_id" => "plan-1",
          "final_amount" => "250.00",
          "is_one_time_item" => 0,
          "cycle_discounts" => []
        }
      ],
      "billing_attempts" => []
    }
  end
  let(:selling_plans) do
    {
      "plan-1" => {
        "selling_plan_id" => "plan-1",
        "pricing_policy_fixed_adjustment_type" => "PERCENTAGE",
        "pricing_policy_fixed_adjustment_value" => "75",
        "billing_max_cycles" => 4
      }
    }
  end

  before do
    allow(Seal::Api::Client).to receive(:new).and_return(client)
    allow(client).to receive(:selling_plans_by_id).and_return(selling_plans)
  end

  it "reconciles every detailed SEAL subscription" do
    allow(client).to receive(:each_subscription_detail).and_yield(subscription)

    expect { described_class.perform_now }
      .to change(SalePaymentPlan, :count).by(1)
      .and change(SalePaymentPart, :count).by(4)

    expect(SalePaymentPlan.sole).to have_attributes(
      provider: "seal",
      external_id: "1",
      expected_parts: 4
    )
  end

  it "never links an origin sale by matching customer or amount when the Seal order id differs" do
    customer = create(:customer)
    create(:sale, customer:, shopify_store_id: "gid://shopify/Order/999", total: BigDecimal("1147.50"))
    allow(client).to receive(:each_subscription_detail).and_yield(subscription)

    described_class.perform_now

    expect(SalePaymentPlan.sole.origin_sale).to be_nil
  end

  describe "reconciliation handoff" do
    it "enqueues one full reconciliation after a complete successful sync" do
      allow(client).to receive(:each_subscription_detail).and_yield(subscription)
      allow(Seal::ReconcileInstallmentSaleItemsJob).to receive(:perform_later)

      described_class.perform_now

      expect(Seal::ReconcileInstallmentSaleItemsJob).to have_received(:perform_later).with(no_args)
    end

    it "enqueues no reconciliation when the sync fails" do
      allow(client).to receive(:each_subscription_detail).and_raise(Seal::Api::Client::ApiError, "provider unavailable")
      allow(Seal::ReconcileInstallmentSaleItemsJob).to receive(:perform_later)

      expect { described_class.perform_now }.to raise_error(Seal::Api::Client::ApiError)

      expect(Seal::ReconcileInstallmentSaleItemsJob).not_to have_received(:perform_later)
    end
  end

  describe "single-flight locking" do
    def raw_pg_connection
      config = ActiveRecord::Base.connection_db_config.configuration_hash
      PG.connect(dbname: config[:database], host: config[:host], port: config[:port], user: config[:username], password: config[:password])
    end

    def hold_competing_lock
      acquired = Queue.new
      release = Queue.new

      thread = Thread.new do
        connection = raw_pg_connection
        connection.exec("SELECT pg_try_advisory_lock(#{described_class::LOCK_KEY})")
        acquired << true
        release.pop
        connection.exec("SELECT pg_advisory_unlock(#{described_class::LOCK_KEY})")
      ensure
        connection&.close
      end
      acquired.pop

      yield
    ensure
      release << true
      thread.join
    end

    def lock_free?
      connection = raw_pg_connection
      free = connection.exec("SELECT pg_try_advisory_lock(#{described_class::LOCK_KEY})").getvalue(0, 0)
      connection.exec("SELECT pg_advisory_unlock(#{described_class::LOCK_KEY})") if free == "t"
      free == "t"
    ensure
      connection&.close
    end

    it "exits without provider calls or writes when a competing sync holds the lock" do
      hold_competing_lock do
        expect(Seal::Api::Client).not_to receive(:new)
        expect { described_class.perform_now }.not_to change(SalePaymentPlan, :count)
      end
    end

    it "releases the lock after a successful run" do
      allow(client).to receive(:each_subscription_detail).and_yield(subscription)

      described_class.perform_now

      expect(lock_free?).to be(true)
    end

    it "releases the lock after the provider request fails" do
      allow(client).to receive(:each_subscription_detail)
        .and_raise(Seal::Api::Client::ApiError, "provider unavailable")

      expect { described_class.perform_now }.to raise_error(Seal::Api::Client::ApiError)

      expect(lock_free?).to be(true)
    end
  end

  describe "USD conversion" do
    let(:origin_date) { Date.new(2026, 8, 21) }

    before do
      create(:exchange_rate, date: origin_date, currency: "USD", rate: BigDecimal("1.1250"))
      allow(client).to receive(:each_subscription_detail).and_yield(subscription)
    end

    it "converts Seal money to USD using the linked origin sale's external date" do
      create(:sale, shopify_store_id: "gid://shopify/Order/100", shopify_created_at: origin_date.to_time)

      described_class.perform_now

      plan = SalePaymentPlan.sole
      expect(plan.projected_total).to eq(BigDecimal("1147.50"))
      expect(plan.parts.first.amount).to eq(BigDecimal("281.25"))
    end

    it "defers monetary reconciliation until the origin sale exists, then converts once on a later sync" do
      described_class.perform_now
      plan = SalePaymentPlan.sole
      expect(plan.projected_total).to be_nil

      create(:sale, shopify_store_id: "gid://shopify/Order/100", shopify_created_at: origin_date.to_time)
      described_class.perform_now

      expect(SalePaymentPlan.sole.id).to eq(plan.id)
      expect(plan.reload.projected_total).to eq(BigDecimal("1147.50"))
    end

    it "repeats reconciliation with the same USD amounts, provider IDs, sequences, links, and active states" do
      create(:sale, shopify_store_id: "gid://shopify/Order/100", shopify_created_at: origin_date.to_time)

      described_class.perform_now
      first_plan = SalePaymentPlan.sole.attributes.except("updated_at", "synced_at")
      first_parts = SalePaymentPlan.sole.parts.order(:sequence).map { |part| part.attributes.except("updated_at") }

      described_class.perform_now
      second_plan = SalePaymentPlan.sole.attributes.except("updated_at", "synced_at")
      second_parts = SalePaymentPlan.sole.parts.order(:sequence).map { |part| part.attributes.except("updated_at") }

      expect(second_plan).to eq(first_plan)
      expect(second_parts).to eq(first_parts)
    end
  end

  describe "correcting a wrong stored projection" do
    let(:rate_date) { Date.new(2026, 8, 21) }
    let(:eight_cycle_subscription) do
      {
        "id" => 1,
        "order_id" => "100",
        "status" => "ACTIVE",
        "billing_max_cycles" => 8,
        "currency" => "EUR",
        "delivery_price" => "20.00",
        "items" => [
          {
            "id" => 10,
            "selling_plan_id" => "plan-1",
            "final_amount" => "56.25",
            "is_one_time_item" => 0,
            "cycle_discounts" => []
          }
        ],
        "billing_attempts" => []
      }
    end

    it "replaces the same record's wrong projection with the corrected installment total" do
      create(:exchange_rate, date: rate_date, currency: "USD", rate: BigDecimal("1.1448"))
      create(:sale, shopify_store_id: "gid://shopify/Order/100", shopify_created_at: rate_date.to_time)
      plan = SalePaymentPlan.reconcile!(
        attributes: {
          provider: "seal",
          external_id: "1",
          external_origin_order_id: "100",
          kind: "installments",
          expected_parts: 8,
          projected_total: BigDecimal("280.48"),
          synced_at: 1.day.ago
        },
        parts: []
      )
      allow(client).to receive(:each_subscription_detail).and_yield(eight_cycle_subscription)

      described_class.perform_now

      expect(SalePaymentPlan.sole.id).to eq(plan.id)
      expect(plan.reload.projected_total).to eq(BigDecimal("538.06"))
    end
  end

  it "preserves the previous snapshot when the provider request fails" do
    plan = SalePaymentPlan.reconcile!(
      attributes: {
        provider: "seal",
        external_id: "1",
        external_origin_order_id: "100",
        kind: "installments",
        status: "active",
        expected_parts: 4,
        synced_at: 1.day.ago
      },
      parts: [{provider_part_id: "part-1", sequence: 1}]
    )
    allow(client).to receive(:each_subscription_detail)
      .and_raise(Seal::Api::Client::ApiError, "provider unavailable")

    expect { described_class.perform_now }.to raise_error(Seal::Api::Client::ApiError)
    expect(plan.reload.expected_parts).to eq(4)
    expect(plan.parts.count).to eq(1)
  end
end
