# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::FormPayload do
  subject(:form_payload) { described_class.new(params:) }

  let(:params) do
    ActionController::Parameters.new(
      sale: {
        status: "processing",
        discount_total: "5.00",
        note: "Test note",
        shipping_total: "10.00",
        total: "100.00",
        customer_id: "12",
        shipping_address: {
          first_name: "Ada",
          city: "London"
        },
        billing_address: {
          first_name: "Grace",
          city: "Paris"
        }
      },
      sale_items: {
        "0" => {
          id: "",
          product_id: "7",
          variant_id: "",
          qty: "2",
          price: "19.99",
          _destroy: "0"
        }
      }
    )
  end

  it "builds sale attributes and nested sale item attributes from submitted rows" do # rubocop:disable RSpec/MultipleExpectations
    expect(form_payload.sale_attributes).to eq(
      status: "processing",
      discount_total: "5.00",
      note: "Test note",
      shipping_total: "10.00",
      total: "100.00",
      customer_id: "12"
    )
    expect(form_payload.shipping_address_attributes).to eq(
      first_name: "Ada",
      city: "London"
    )
    expect(form_payload.billing_address_attributes).to eq(
      first_name: "Grace",
      city: "Paris"
    )
    expect(form_payload.sale_item_attributes).to eq([
      {
        product_id: "7",
        qty: "2",
        price: "19.99",
        destroy: false
      }
    ])
  end
end
