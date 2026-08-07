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
