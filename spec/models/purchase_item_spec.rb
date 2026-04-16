# frozen_string_literal: true

# == Schema Information
#
# Table name: purchase_items
#
#  id                  :bigint           not null, primary key
#  expenses            :decimal(8, 2)
#  height              :integer
#  length              :integer
#  shipping_cost       :decimal(8, 2)    default(0.0), not null
#  tracking_number     :string
#  weight              :integer
#  width               :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  purchase_id         :bigint
#  sale_item_id        :bigint
#  shipping_company_id :bigint
#  warehouse_id        :bigint           not null
#
require "rails_helper"

describe PurchaseItem do
  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe "search" do
    let!(:matching_customer) do
      create(:customer, email: "michele@example.com", first_name: "Michele", last_name: "Pomarico")
    end
    let!(:matching_sale) { create(:sale, customer: matching_customer, shopify_name: "Order Alpha", woo_id: "sale-woo-123") }
    let!(:matching_product) { create(:product, title: "Spirited Away") }
    let!(:matching_purchase) do
      create(:purchase, product: matching_product, order_reference: "PUR-ALPHA-123")
    end
    let!(:matching_shipping_company) { create(:shipping_company, name: "DHL Express") }
    let!(:matching_purchase_item) do
      create(
        :purchase_item,
        purchase: matching_purchase,
        shipping_company: matching_shipping_company,
        tracking_number: "TRACK-ALPHA-123"
      )
    end
    let!(:other_purchase_item) do
      create(
        :purchase_item,
        tracking_number: "TRACK-BETA-456",
        shipping_company: create(:shipping_company, name: "FedEx Priority")
      )
    end

    before do
      create(:sale_item, sale: matching_sale, product: matching_product, purchase_items: [matching_purchase_item])
    end

    it "finds purchase items by prefixes from their own and associated searchable fields" do
      aggregate_failures do
        expect(described_class.search_by("TRACK-AL")).to include(matching_purchase_item)
        expect(described_class.search_by("PUR-AL")).to include(matching_purchase_item)
        expect(described_class.search_by("Spiri")).to include(matching_purchase_item)
        expect(described_class.search_by("mich")).to include(matching_purchase_item)
        expect(described_class.search_by("DHL Ex")).to include(matching_purchase_item)
      end
    end

    it "returns all purchase items when the query is blank" do
      expect(described_class.search_by("")).to match_array([matching_purchase_item, other_purchase_item])
    end

    it "returns no purchase items when nothing matches" do
      expect(described_class.search_by("nonexistent")).to be_empty
    end
  end

  describe "#warehouse_movements" do
    it "returns warehouse history from audits" do
      first_warehouse = create(:warehouse, name: "First Warehouse")
      second_warehouse = create(:warehouse, name: "Second Warehouse")
      third_warehouse = create(:warehouse, name: "Third Warehouse")
      purchase_item = create(:purchase_item, warehouse: first_warehouse)

      purchase_item.move_to_warehouse!(second_warehouse.id)
      purchase_item.move_to_warehouse!(third_warehouse.id)

      expect(
        purchase_item.reload.warehouse_movements.map { |movement| [movement.warehouse&.name, movement.moved_in.to_i] }
      ).to eq([
        ["First Warehouse", purchase_item.audits.first.created_at.to_i],
        ["Second Warehouse", purchase_item.audits.second.created_at.to_i],
        ["Third Warehouse", purchase_item.audits.third.created_at.to_i]
      ])
    end
  end
end
