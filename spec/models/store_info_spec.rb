# == Schema Information
#
# Table name: store_infos
#
#  id               :bigint           not null, primary key
#  name             :integer          default("not_assigned"), not null
#  pull_time        :datetime
#  push_time        :datetime
#  slug             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  product_id       :bigint           not null
#  store_product_id :string
#
require "rails_helper"

RSpec.describe StoreInfo, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:product) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:name).with_values(not_assigned: 0, shopify: 1, woo: 2) }
  end

  describe "page_url" do
    it "generates correct URL from slug" do
      store_info = build(:store_info, slug: "test-product")
      expect(store_info.page_url).to eq("https://handsomecake.com/products/test-product")
    end
  end

  describe "factory traits" do
    let(:product) { create(:product) }

    it "creates shopify store info" do
      store_info = create(:store_info, :shopify, product: product)
      expect(store_info.name).to eq("shopify")
    end

    it "creates woo store info" do
      store_info = create(:store_info, :woo, product: product)
      expect(store_info.name).to eq("woo")
    end

    it "creates with store product id" do
      store_info = create(:store_info, :with_store_product_id, product: product)
      expect(store_info.store_product_id).to eq("gid://shopify/Product/12345")
    end

    it "creates with slug" do
      store_info = create(:store_info, :with_slug, product: product)
      expect(store_info.slug).to eq("test-product")
    end

    it "creates with push time" do
      store_info = create(:store_info, :with_push_time, product: product)
      expect(store_info.push_time).to be_within(1.second).of(Time.current)
    end
  end
end
