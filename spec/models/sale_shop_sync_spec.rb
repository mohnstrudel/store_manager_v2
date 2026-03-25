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
      let(:sale) { create(:sale) }

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
      let(:sale) { create(:sale, shopify_id: nil) }

      it "returns woo_updated_at" do
        sale.update!(woo_updated_at: 2.days.ago)
        expect(sale.shop_updated_at).to be_within(1.second).of(2.days.ago)
      end
    end

    context "when sale has both shopify_info and woo_updated_at" do
      let(:sale) { create(:sale) }

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

  describe "#sync_status_change_to_shop!" do
    it "pushes the sale through the class-level sync entrypoint" do
      sale = create(:sale)
      allow(described_class).to receive(:update_order)

      sale.sync_status_change_to_shop!

      expect(described_class).to have_received(:update_order).with(sale)
    end
  end
end
