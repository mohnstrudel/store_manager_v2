# frozen_string_literal: true

# == Schema Information
#
# Table name: sales
#
#  id                 :bigint           not null, primary key
#  address_1          :string
#  address_2          :string
#  cancel_reason      :string
#  cancelled_at       :datetime
#  city               :string
#  closed             :boolean          default(FALSE)
#  closed_at          :datetime
#  company            :string
#  confirmed          :boolean          default(FALSE)
#  country            :string
#  discount_total     :decimal(8, 2)
#  financial_status   :string
#  fulfillment_status :string
#  note               :string
#  postcode           :string
#  return_status      :string
#  shipping_total     :decimal(8, 2)
#  shopify_created_at :datetime
#  shopify_name       :string
#  shopify_updated_at :datetime
#  slug               :string
#  state              :string
#  status             :string
#  total              :decimal(8, 2)
#  woo_created_at     :datetime
#  woo_updated_at     :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  customer_id        :bigint           not null
#  shopify_id         :string
#  woo_id             :string
#
require "rails_helper"

RSpec.describe Sale do
  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe "search" do
    let!(:matching_customer) do
      create(
        :customer,
        email: "michele@example.com",
        first_name: "Michele",
        last_name: "Pomarico",
        phone: "+491729364665",
        woo_id: "cust-woo-123"
      )
    end
    let!(:matching_sale) do
      create(
        :sale,
        customer: matching_customer,
        shopify_name: "Order Alpha",
        note: "Fragile shipment",
        status: "processing",
        financial_status: "paid",
        fulfillment_status: "fulfilled",
        woo_id: "sale-woo-123",
        shopify_id: "gid://shopify/Order/123"
      )
    end
    let!(:matching_product) { create(:product, title: "Spirited Away") }
    let!(:other_sale) { create(:sale, shopify_name: "Order Beta", note: "Standard") }

    before do
      create(:sale_item, sale: matching_sale, product: matching_product)
    end

    it "finds sales by prefixes from their own and associated searchable fields" do
      aggregate_failures do
        expect(described_class.search_by("Order Al")).to include(matching_sale)
        expect(described_class.search_by("Frag")).to include(matching_sale)
        expect(described_class.search_by("proc")).to include(matching_sale)
        expect(described_class.search_by("mich")).to include(matching_sale)
        expect(described_class.search_by("Spiri")).to include(matching_sale)
      end
    end

    it "returns all sales when the query is blank" do
      expect(described_class.search_by("")).to match_array([matching_sale, other_sale])
    end

    it "returns no sales when nothing matches" do
      expect(described_class.search_by("nonexistent")).to be_empty
    end
  end
end
