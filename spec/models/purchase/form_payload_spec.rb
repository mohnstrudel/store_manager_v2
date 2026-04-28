# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchase::FormPayload do
  subject(:payload) { described_class.new(params:) }

  let(:params) do
    ActionController::Parameters.new(
      purchase: {
        supplier_id: "1",
        product_id: "2",
        variant_id: "3",
        order_reference: "REF-1",
        item_price: "12.50",
        amount: "5",
        warehouse_id: "9"
      },
      initial_payment: {
        value: "62.50"
      }
    )
  end

  it "separates persisted purchase attributes from the initial warehouse choice" do # rubocop:disable RSpec/MultipleExpectations
    expect(payload.attributes).to eq(
      "supplier_id" => "1",
      "product_id" => "2",
      "variant_id" => "3",
      "order_reference" => "REF-1",
      "item_price" => "12.50",
      "amount" => "5"
    )
    expect(payload.initial_warehouse_id).to eq("9")
    expect(payload.initial_payment_value).to eq("62.50")
  end
end
