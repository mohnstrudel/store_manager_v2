# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::FormPayload do
  subject(:payload) { described_class.new(params:) }

  let(:params) do
    ActionController::Parameters.new(
      product: {
        title: "Test Product",
        sku: "SKU-1",
        franchise_id: "1",
        shape_id: "2",
        brand_ids: ["3"],
        color_ids: ["4"],
        size_ids: ["5"],
        version_ids: ["6"]
      },
      store_infos: {
        "0" => {
          id: "7",
          tag_list: "anime,figure",
          store_name: "shopify",
          _destroy: "0"
        }
      },
      editions: {
        "0" => {
          id: "",
          sku: "ED-1",
          size_id: "10",
          version_id: "11",
          color_id: "12",
          purchase_cost: "9.99",
          selling_price: "19.99",
          weight: "1.5",
          _destroy: "0"
        }
      },
      initial_purchase: {
        supplier_id: "13",
        order_reference: "PO-42",
        item_price: "9.99",
        amount: "3",
        warehouse_id: "14",
        payment_value: "29.97"
      }
    )
  end

  it "builds domain-friendly attributes for the product form" do # rubocop:disable RSpec/MultipleExpectations
    expect(payload.product_attributes["title"]).to eq("Test Product")
    expect(payload.editions_attributes).to eq([
      {
        sku: "ED-1",
        size_id: "10",
        version_id: "11",
        color_id: "12",
        purchase_cost: "9.99",
        selling_price: "19.99",
        weight: "1.5",
        destroy: false
      }
    ])
    expect(payload.store_infos_attributes).to eq([
      {
        id: "7",
        tag_list: "anime,figure",
        store_name: "shopify",
        destroy: false
      }
    ])
    expect(payload.initial_purchase_attributes).to eq({
      supplier_id: "13",
      order_reference: "PO-42",
      item_price: "9.99",
      amount: "3",
      warehouse_id: "14",
      payment_value: "29.97"
    })
  end
end
