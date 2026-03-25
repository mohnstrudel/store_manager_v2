# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#active_sale_items" do
    let(:product) { create(:product) }
    let(:edition) { create(:edition, product:) }

    let!(:older_active_sale_item) do
      create(:sale_item,
        product:,
        edition:,
        sale: create(:sale, status: "processing"),
        qty: 2,
        created_at: 2.days.ago,
        updated_at: 2.days.ago)
    end

    let!(:newer_active_sale_item) do
      create(:sale_item,
        product:,
        edition:,
        sale: create(:sale, status: "pre-ordered"),
        qty: 1,
        created_at: 1.day.ago,
        updated_at: 1.day.ago)
    end

    let!(:completed_sale_item) do
      create(:sale_item,
        product:,
        edition:,
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
    let(:edition) { create(:edition, product:) }

    let!(:completed_sale_item) do
      create(:sale_item,
        product:,
        edition:,
        sale: create(:sale, status: "completed"),
        qty: 4,
        created_at: 1.day.ago,
        updated_at: 1.day.ago)
    end

    let!(:active_sale_item) do
      create(:sale_item,
        product:,
        edition:,
        sale: create(:sale, status: "processing"),
        qty: 2,
        created_at: 2.days.ago,
        updated_at: 2.days.ago)
    end

    it "returns completed sale items ordered by creation time" do
      expect(product.completed_sale_items).to eq([completed_sale_item])
    end
  end

  describe "#edition_sales_sums" do
    let(:product) { create(:product) }
    let(:edition1) { create(:edition, product:) }
    let(:edition2) { create(:edition, product:) }

    before do
      create(:sale_item, product:, edition: edition1, sale: create(:sale, status: "processing"), qty: 2)
      create(:sale_item, product:, edition: edition1, sale: create(:sale, status: "completed"), qty: 9)
      create(:sale_item, product:, edition: edition2, sale: create(:sale, status: "partially-paid"), qty: 5)
    end

    it "sums active sale quantities per edition" do
      expect(product.edition_sales_sums).to eq(
        edition1.id => 2,
        edition2.id => 5
      )
    end
  end

  describe "#edition_purchase_sums" do
    let(:product) { create(:product) }
    let(:edition1) { create(:edition, product:) }
    let(:edition2) { create(:edition, product:) }

    before do
      create(:purchase, product:, edition: edition1, amount: 3, item_price: 10)
      create(:purchase, product:, edition: edition1, amount: 2, item_price: 10)
      create(:purchase, product:, edition: edition2, amount: 7, item_price: 10)
    end

    it "sums purchase amounts per edition" do
      expect(product.edition_purchase_sums).to eq(
        edition1.id => 5,
        edition2.id => 7
      )
    end
  end
end
