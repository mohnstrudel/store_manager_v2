# frozen_string_literal: true

# == Schema Information
#
# Table name: editions
#
#  id             :bigint           not null, primary key
#  deactivated_at :datetime
#  purchase_cost  :decimal(10, 2)   default(0.0), not null
#  selling_price  :decimal(10, 2)   default(0.0), not null
#  sku            :string
#  weight         :decimal(10, 2)   default(0.0), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  color_id       :bigint
#  product_id     :bigint           not null
#  shopify_id     :string
#  size_id        :bigint
#  version_id     :bigint
#  woo_id         :string
#
require "rails_helper"

RSpec.describe Edition do
  describe "validations" do
    it "enforces persisted sku uniqueness" do # rubocop:todo RSpec/MultipleExpectations
      create(:edition, sku: "DUPLICATE-SKU")
      duplicate = build(:edition, sku: "DUPLICATE-SKU")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:sku]).to include("has already been taken")
    end
  end

  describe "price" do
    it "returns 0.0 since price tracking was removed from StoreInfo" do
      edition = create(:edition)
      expect(edition.price).to eq(0.0)
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe "#deactivated?" do
    context "when edition is active" do
      let(:edition) { create(:edition, version: nil) }

      it "returns false" do
        expect(edition.deactivated?).to be false
      end
    end

    context "when edition is deactivated" do
      let(:edition) { create(:edition, version: nil, deactivated_at: Time.current) }

      it "returns true" do
        expect(edition.deactivated?).to be true
      end
    end
  end

  describe "#has_sales_or_purchases?" do
    let(:product) { create(:product) }
    let(:edition) { described_class.create!(product: product) }

    context "when edition has no sale_items or purchases" do
      it "returns false" do
        expect(edition.has_sales_or_purchases?).to be false
      end
    end

    context "when edition has sale_items" do
      let(:sale) { create(:sale) }

      before do
        SaleItem.create!(product: product, edition: edition, sale: sale, qty: 1)
      end

      it "returns true" do
        expect(edition.has_sales_or_purchases?).to be true
      end
    end

    context "when edition has purchases" do
      let(:supplier) { create(:supplier) }

      before do
        Purchase.create!(product: product, edition: edition, supplier: supplier, amount: 1, item_price: 10)
      end

      it "returns true" do
        expect(edition.has_sales_or_purchases?).to be true
      end
    end
  end

  describe ".active scope" do
    let!(:active_edition) { described_class.create!(product: create(:product)) }
    let!(:deactivated_edition) { described_class.create!(product: create(:product), deactivated_at: Time.current) }

    it "includes active editions" do
      expect(described_class.active).to include(active_edition)
    end

    it "excludes deactivated editions" do
      expect(described_class.active).not_to include(deactivated_edition)
    end
  end

  describe ".deactivated scope" do
    let!(:active_edition) { described_class.create!(product: create(:product)) }
    let!(:deactivated_edition) { described_class.create!(product: create(:product), deactivated_at: Time.current) }

    it "includes deactivated editions" do
      expect(described_class.deactivated).to include(deactivated_edition)
    end

    it "excludes active editions" do
      expect(described_class.deactivated).not_to include(active_edition)
    end
  end
end
