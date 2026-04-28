# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#active_sale_items" do
    let(:product) { create(:product) }
    let(:variant) { create(:variant, product:) }

    let!(:older_active_sale_item) do
      create(:sale_item,
        product:,
        variant:,
        sale: create(:sale, status: "processing"),
        qty: 2,
        created_at: 2.days.ago,
        updated_at: 2.days.ago)
    end

    let!(:newer_active_sale_item) do
      create(:sale_item,
        product:,
        variant:,
        sale: create(:sale, status: "pre-ordered"),
        qty: 1,
        created_at: 1.day.ago,
        updated_at: 1.day.ago)
    end

    let!(:completed_sale_item) do
      create(:sale_item,
        product:,
        variant:,
        sale: create(:sale, status: "completed"),
        qty: 5,
        created_at: 3.days.ago,
        updated_at: 3.days.ago)
    end

    it "returns active sale items ordered by creation time" do
      expect(product.active_sale_items).to eq([older_active_sale_item, newer_active_sale_item])
    end
  end

  describe "#completed_sale_items" do
    let(:product) { create(:product) }
    let(:variant) { create(:variant, product:) }

    let!(:completed_sale_item) do
      create(:sale_item,
        product:,
        variant:,
        sale: create(:sale, status: "completed"),
        qty: 4,
        created_at: 1.day.ago,
        updated_at: 1.day.ago)
    end

    let!(:active_sale_item) do
      create(:sale_item,
        product:,
        variant:,
        sale: create(:sale, status: "processing"),
        qty: 2,
        created_at: 2.days.ago,
        updated_at: 2.days.ago)
    end

    it "returns completed sale items ordered by creation time" do
      expect(product.completed_sale_items).to eq([completed_sale_item])
    end
  end

  describe "#variant_sales_sums" do
    let(:product) { create(:product) }
    let(:variant1) { create(:variant, product:) }
    let(:variant2) { create(:variant, product:) }

    before do
      create(:sale_item, product:, variant: variant1, sale: create(:sale, status: "processing"), qty: 2)
      create(:sale_item, product:, variant: variant1, sale: create(:sale, status: "completed"), qty: 9)
      create(:sale_item, product:, variant: variant2, sale: create(:sale, status: "partially-paid"), qty: 5)
    end

    it "sums active sale quantities per variant" do
      expect(product.variant_sales_sums).to eq(
        variant1.id => 2,
        variant2.id => 5
      )
    end
  end

  describe "#variant_purchase_sums" do
    let(:product) { create(:product) }
    let(:variant1) { create(:variant, product:) }
    let(:variant2) { create(:variant, product:) }

    before do
      create(:purchase, product:, variant: variant1, amount: 3, item_price: 10)
      create(:purchase, product:, variant: variant1, amount: 2, item_price: 10)
      create(:purchase, product:, variant: variant2, amount: 7, item_price: 10)
    end

    it "sums purchase amounts per variant" do
      expect(product.variant_purchase_sums).to eq(
        variant1.id => 5,
        variant2.id => 7
      )
    end
  end
end
