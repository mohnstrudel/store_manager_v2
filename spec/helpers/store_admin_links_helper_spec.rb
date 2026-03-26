# frozen_string_literal: true

require "rails_helper"

RSpec.describe StoreAdminLinksHelper do
  describe "#sale_shop_link" do
    it "builds a Shopify admin URL for Shopify sales" do
      sale = create(:sale)

      expect(helper.sale_shop_link(sale)).to include("/orders/#{sale.shopify_info.id_short}")
    end
  end

  describe "#customer_shop_link" do
    it "builds a Shopify admin URL for Shopify customers" do
      customer = create(:customer)
      create(:store_info, :shopify, storable: customer, store_id: "gid://shopify/Customer/123")

      expect(helper.customer_shop_link(customer)).to include("/customers/#{customer.shopify_info.id_short}")
    end
  end
end
