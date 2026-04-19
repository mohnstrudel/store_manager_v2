# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopable do
  describe "#link_shopify_info!" do
    let(:record) do
      create(:product_with_brands).tap do |created_product|
        created_product.store_infos.destroy_all
      end
    end
    let(:store_id) { "gid://shopify/Product/12345" }
    let(:slug) { "test-product" }

    it "creates a Shopify store info when missing" do
      expect {
        record.link_shopify_info!(store_id:, slug:)
      }.to change { record.store_infos.shopify.count }.by(1)
    end

    it "stores the Shopify product ID" do
      store_info = record.link_shopify_info!(store_id:, slug:)

      expect(store_info.store_id).to eq("gid://shopify/Product/12345")
    end

    it "stores the product slug" do
      store_info = record.link_shopify_info!(store_id:, slug:)

      expect(store_info.slug).to eq("test-product")
    end

    context "when Shopify store info already exists" do
      let(:record) { create(:product_with_brands) }
      let!(:existing_store_info) do
        record.shopify_info.tap do |store_info|
          store_info.update!(store_id: "old-id", slug: "old-handle")
        end
      end

      it "updates the existing Shopify store info", :aggregate_failures do
        expect {
          record.link_shopify_info!(store_id:, slug:)
        }.not_to change { record.store_infos.shopify.count }

        expect(existing_store_info.reload.store_id).to eq("gid://shopify/Product/12345")
      end
    end

    it "can upsert another store via the shared method", :aggregate_failures do
      store_info = record.update_or_create_store_info!(store_name: :woo, store_id: "woo-123", slug:)

      expect(store_info.store_name).to eq("woo")
      expect(store_info.store_id).to eq("woo-123")
    end
  end

  describe "#mark_shopify_pushed!" do
    let(:record) { create(:product_with_brands) }

    it "sets the push time" do
      before_time = Time.current

      store_info = record.mark_shopify_pushed!

      expect(store_info.push_time).to be_between(before_time, Time.current).inclusive
    end
  end

  describe "#mark_shopify_pulled!" do
    let(:record) { create(:product_with_brands) }

    it "sets the pull time" do
      before_time = Time.current

      store_info = record.mark_shopify_pulled!

      expect(store_info.pull_time).to be_between(before_time, Time.current).inclusive
    end
  end
end
