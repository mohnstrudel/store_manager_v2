# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#active_sale_items" do
    let(:product) { create(:product) }
    let(:variant) { create(:variant, product:) }
    let(:warehouse) { create(:warehouse) }
    let(:supplier) { create(:supplier) }

    let!(:older_active_sale_item) do
      sale = create(:sale, status: "processing")
      create(:sale_address, sale:, kind: :shipping)
      sale_item = create(:sale_item,
        product:,
        variant:,
        sale:,
        qty: 2,
        created_at: 2.days.ago,
        updated_at: 2.days.ago)
      create(:purchase_item,
        sale_item:,
        purchase: create(:purchase, product:, variant:, supplier:),
        warehouse:)
      sale_item
    end

    let!(:newer_active_sale_item) do
      sale = create(:sale, status: "pre-ordered")
      create(:sale_address, sale:, kind: :shipping)
      sale_item = create(:sale_item,
        product:,
        variant:,
        sale:,
        qty: 1,
        created_at: 1.day.ago,
        updated_at: 1.day.ago)
      create(:purchase_item,
        sale_item:,
        purchase: create(:purchase, product:, variant:, supplier:),
        warehouse:)
      sale_item
    end

    it "returns active sale items ordered by creation time" do
      expect(product.active_sale_items).to eq([older_active_sale_item, newer_active_sale_item])
    end

    it "preloads the full history tree for the active sales table" do
      product.active_sale_items.each do |sale_item|
        sale_association = sale_item.association(:sale)
        purchase_items_association = sale_item.association(:purchase_items)

        aggregate_failures do
          expect(sale_association).to be_loaded
          expect(sale_item.association(:product)).to be_loaded
          expect(sale_item.association(:variant)).to be_loaded
          expect(purchase_items_association).to be_loaded

          sale = sale_association.target
          purchase_item = purchase_items_association.target.first

          expect(sale.association(:customer)).to be_loaded
          expect(sale.association(:shopify_info)).to be_loaded
          expect(sale.association(:woo_info)).to be_loaded
          expect(sale.association(:shipping_address)).to be_loaded
          expect(purchase_item.association(:warehouse)).to be_loaded
        end
      end
    end
  end

  describe "#completed_sale_items" do
    let(:product) { create(:product) }
    let(:variant) { create(:variant, product:) }
    let(:warehouse) { create(:warehouse) }
    let(:supplier) { create(:supplier) }

    let!(:completed_sale_item) do
      sale = create(:sale, status: "completed")
      create(:sale_address, sale:, kind: :shipping)
      sale_item = create(:sale_item,
        product:,
        variant:,
        sale:,
        qty: 4,
        created_at: 1.day.ago,
        updated_at: 1.day.ago)
      create(:purchase_item,
        sale_item:,
        purchase: create(:purchase, product:, variant:, supplier:),
        warehouse:)
      sale_item
    end

    it "returns completed sale items ordered by creation time" do
      expect(product.completed_sale_items).to eq([completed_sale_item])
    end

    it "preloads the full history tree for the completed sales table" do
      sale_item = product.completed_sale_items.first
      sale_association = sale_item.association(:sale)
      purchase_items_association = sale_item.association(:purchase_items)

      aggregate_failures do
        expect(sale_association).to be_loaded
        expect(sale_item.association(:product)).to be_loaded
        expect(sale_item.association(:variant)).to be_loaded
        expect(purchase_items_association).to be_loaded

        sale = sale_association.target
        purchase_item = purchase_items_association.target.first

        expect(sale.association(:customer)).to be_loaded
        expect(sale.association(:shopify_info)).to be_loaded
        expect(sale.association(:woo_info)).to be_loaded
        expect(sale.association(:shipping_address)).to be_loaded
        expect(purchase_item.association(:warehouse)).to be_loaded
      end
    end
  end

  describe "#variant_sales_sums" do
    let(:product) { create(:product) }
    let(:primary_variant) { create(:variant, product:) }
    let(:secondary_variant) { create(:variant, product:) }

    before do
      create(:sale_item, product:, variant: primary_variant, sale: create(:sale, status: "processing"), qty: 2)
      create(:sale_item, product:, variant: primary_variant, sale: create(:sale, status: "completed"), qty: 9)
      create(:sale_item, product:, variant: secondary_variant, sale: create(:sale, status: "partially-paid"), qty: 5)
    end

    it "sums active sale quantities per variant" do
      expect(product.variant_sales_sums).to eq(
        primary_variant.id => 2,
        secondary_variant.id => 5
      )
    end
  end

  describe "#variant_purchase_sums" do
    let(:product) { create(:product) }
    let(:primary_variant) { create(:variant, product:) }
    let(:secondary_variant) { create(:variant, product:) }

    before do
      create(:purchase, product:, variant: primary_variant, amount: 3, item_price: 10)
      create(:purchase, product:, variant: primary_variant, amount: 2, item_price: 10)
      create(:purchase, product:, variant: secondary_variant, amount: 7, item_price: 10)
    end

    it "sums purchase amounts per variant" do
      expect(product.variant_purchase_sums).to eq(
        primary_variant.id => 5,
        secondary_variant.id => 7
      )
    end
  end
end
