# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale do
  describe "#shop_created_at" do
    context "when shopify_created_at is present" do
      it "returns shopify_created_at" do
        sale = create(:sale, shopify_created_at: 1.day.ago)

        expect(sale.shop_created_at).to be_within(1.second).of(1.day.ago)
      end
    end

    context "when shopify_created_at is blank" do
      it "returns woo_created_at" do
        sale = create(:sale, shopify_created_at: nil, woo_created_at: 2.days.ago)

        expect(sale.shop_created_at).to be_within(1.second).of(2.days.ago)
      end
    end
  end

  describe "#shop_updated_at" do
    context "when sale has shopify_info with ext_updated_at" do
      let(:sale) { create(:sale, :synced) }

      it "returns ext_updated_at from shopify_info" do
        sale.shopify_info.update!(ext_updated_at: 1.day.ago)
        expect(sale.shop_updated_at).to be_within(1.second).of(1.day.ago)
      end

      it "returns nil when ext_updated_at is nil and woo_updated_at is nil" do
        sale.shopify_info.update!(ext_updated_at: nil)
        sale.update!(woo_updated_at: nil)
        expect(sale.shop_updated_at).to be_nil
      end
    end

    context "when sale has woo_updated_at" do
      let(:sale) { create(:sale, :synced, shopify_id: nil) }

      it "returns woo_updated_at" do
        sale.update!(woo_updated_at: 2.days.ago)
        expect(sale.shop_updated_at).to be_within(1.second).of(2.days.ago)
      end
    end

    context "when sale has both shopify_info and woo_updated_at" do
      let(:sale) { create(:sale, :synced) }

      it "prioritizes shopify_info.ext_updated_at over woo_updated_at" do
        sale.shopify_info.update!(ext_updated_at: 1.day.ago)
        sale.update!(woo_updated_at: 2.days.ago)
        expect(sale.shop_updated_at).to be_within(1.second).of(1.day.ago)
      end
    end
  end

  describe ".find_recent_by_order_id" do
    it "finds by shopify_name when prefixed with HSCM#" do
      sale = create(:sale, shopify_name: "HSCM#123")

      expect(described_class.find_recent_by_order_id("HSCM#123")).to eq(sale)
    end

    it "falls back to matching shopify_name suffix or woo_id" do
      sale = create(:sale, shopify_name: "ORDER-123", woo_id: "123")

      expect(described_class.find_recent_by_order_id("123")).to eq(sale)
    end
  end

  describe "#shopify_variant_unlinked?" do
    let(:sale) { create(:sale) }
    let(:shopify_variant_id) { "gid://shopify/ProductVariant/50971387363657" }

    it "is true when any item's Shopify variant has no local match" do
      create(:sale_item, sale:, shopify_variant_id: nil)
      create(:sale_item, sale:, shopify_variant_id:)

      expect(sale).to be_shopify_variant_unlinked
    end

    it "is false once every item's Shopify variant is linked or absent" do
      product = create(:product)
      linked = create(:variant, product:, shopify_store_id: shopify_variant_id)
      create(:sale_item, sale:, product:, variant: linked, shopify_variant_id:)
      create(:sale_item, sale:, shopify_variant_id: nil)

      expect(sale).not_to be_shopify_variant_unlinked
    end

    it "is false for a sale without items" do
      expect(sale).not_to be_shopify_variant_unlinked
    end

    it "answers from preloaded items and links without querying" do
      create(:sale_item, sale:, shopify_variant_id:)
      preloaded = described_class.includes(sale_items: :shopify_variant_info).find(sale.id)
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| queries << payload[:sql] }

      preloaded.shopify_variant_unlinked?

      expect(queries).to be_empty
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end

  describe "#push_status_to_woo_later" do
    it "enqueues the Woo status push" do
      sale = create(:sale)

      expect { sale.push_status_to_woo_later }
        .to have_enqueued_job(Woo::PushSaleJob).with(sale)
    end
  end

  describe "#push_status_to_woo_now" do
    it "posts the sale status to its Woo order" do
      sale = create(:sale, woo_store_id: "4321", status: "completed")
      client = instance_double(Woo::Api::Client)
      allow(Woo::Api::Client).to receive(:new).and_return(client)
      allow(client).to receive(:update_order_status)

      sale.push_status_to_woo_now

      expect(client).to have_received(:update_order_status).with("4321", "completed")
    end
  end
end
