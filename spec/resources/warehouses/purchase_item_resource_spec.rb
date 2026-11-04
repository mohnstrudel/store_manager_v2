# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouses::PurchaseItemResource do
  describe "sale_summary" do
    it "formats the linked sale summary for the warehouse view" do
      sale = create(:sale)
      purchase_item = create(:purchase_item, sale_item: create(:sale_item, sale:))

      expect(serialize(purchase_item.reload)[:sale_summary]).to include(sale.customer.full_name)
    end

    it "is blank without a linked sale" do
      expect(serialize(create(:purchase_item))[:sale_summary]).to eq("")
    end
  end

  describe "inline editor values" do
    it "serves blank strings when tracking number and shipping company are missing" do
      props = serialize(create(:purchase_item, tracking_number: nil, shipping_company: nil))

      expect(props).to include(tracking_number: "", shipping_company_name: "", shipping_company_id: nil)
    end
  end

  def serialize(purchase_item)
    described_class.new(purchase_item).serializable_hash.deep_symbolize_keys
  end
end
