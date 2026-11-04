# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customers::SaleResource do
  it "names the first sold product and counts the others" do
    sale = create(:sale)
    first_item = create(:sale_item, sale:)
    create_list(:sale_item, 2, sale:)

    props = described_class.new(sale.reload).serializable_hash.deep_symbolize_keys

    expect(props[:sold_product_name]).to eq("#{first_item.title} + 2 more")
  end

  it "uses the short Shopify id as the store id of a Shopify sale" do
    sale = create(:sale, shopify_store_id: "gid://shopify/Order/987")

    props = described_class.new(sale).serializable_hash.deep_symbolize_keys

    expect(props).to include(store_type: "shopify", store_id: sale.shopify_info.id_short, sold_product_name: "")
  end
end
