# == Schema Information
#
# Table name: store_infos
#
#  id            :bigint           not null, primary key
#  pull_time     :datetime
#  push_time     :datetime
#  slug          :string
#  storable_type :string           not null
#  store_name    :integer          default("not_assigned"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  storable_id   :bigint           not null
#  store_id      :string
#
require "rails_helper"

RSpec.describe StoreInfo, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:storable) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:store_name).with_values(not_assigned: 0, shopify: 1, woo: 2) }
  end

  describe "page_url_for" do
    it "generates correct URL for shopify" do
      store_info = build(:store_info, slug: "test-product")
      expect(store_info.page_url_for(:shopify)).to eq("https://handsomecake.com/products/test-product")
    end

    it "generates correct URL for woo" do
      store_info = build(:store_info, slug: "test-product")
      expect(store_info.page_url_for(:woo)).to eq("https://store.handsomecake.com/product/test-product")
    end
  end

  describe "factory traits" do
    let(:product) { create(:product) }

    it "creates shopify store info" do # rubocop:todo RSpec/MultipleExpectations
      store_info = create(:store_info, :shopify, storable: product)
      expect(store_info.store_name).to eq("shopify")
      expect(store_info.storable).to eq(product)
    end

    it "creates woo store info" do # rubocop:todo RSpec/MultipleExpectations
      store_info = create(:store_info, :woo, storable: product)
      expect(store_info.store_name).to eq("woo")
      expect(store_info.storable).to eq(product)
    end

    it "creates with store product id" do # rubocop:todo RSpec/MultipleExpectations
      store_info = create(:store_info, :with_store_id, storable: product)
      expect(store_info.store_id).to eq("gid://shopify/Product/12345")
      expect(store_info.storable).to eq(product)
    end

    it "creates with slug" do # rubocop:todo RSpec/MultipleExpectations
      store_info = create(:store_info, :with_slug, storable: product)
      expect(store_info.slug).to eq("test-product")
      expect(store_info.storable).to eq(product)
    end

    it "creates with push time" do # rubocop:todo RSpec/MultipleExpectations
      store_info = create(:store_info, :with_push_time, storable: product)
      expect(store_info.push_time).to be_within(1.second).of(Time.current)
      expect(store_info.storable).to eq(product)
    end
  end
end
