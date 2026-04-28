# frozen_string_literal: true

# == Schema Information
#
# Table name: variants
#
#  id             :bigint           not null, primary key
#  deactivated_at :datetime
#  purchase_cost  :decimal(10, 2)   default(0.0), not null
#  selling_price  :decimal(10, 2)   default(0.0), not null
#  sku            :string           not null
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

RSpec.describe Variant do
  describe "validations" do
    it "requires sku to be present" do
      variant = build(:variant, sku: nil)

      variant.validate
      expect(variant.errors[:sku]).to include("can't be blank")
    end

    it "allows the same sku on variants from different products" do # rubocop:todo RSpec/MultipleExpectations
      create(:variant, sku: "DUPLICATE-SKU")
      duplicate = build(:variant, sku: "DUPLICATE-SKU")

      expect(duplicate).to be_valid
      expect(duplicate.errors[:sku]).to be_empty
    end
  end

  describe "price" do
    it "returns 0.0 since price tracking was removed from StoreInfo" do
      variant = create(:variant)
      expect(variant.price).to eq(0.0)
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe "#deactivated?" do
    context "when variant is active" do
      let(:variant) { create(:product).base_variant }

      it "returns false" do
        expect(variant.deactivated?).to be false
      end
    end

    context "when variant is deactivated" do
      let(:variant) { create(:product).base_variant.tap { |base_variant| base_variant.update!(deactivated_at: Time.current) } }

      it "returns true" do
        expect(variant.deactivated?).to be true
      end
    end
  end

  describe "#has_sales_or_purchases?" do
    let(:product) { create(:product) }
    let(:variant) { product.base_variant }

    context "when variant has no sale_items or purchases" do
      it "returns false" do
        expect(variant.has_sales_or_purchases?).to be false
      end
    end

    context "when variant has sale_items" do
      let(:sale) { create(:sale) }

      before do
        SaleItem.create!(product: product, variant: variant, sale: sale, qty: 1)
      end

      it "returns true" do
        expect(variant.has_sales_or_purchases?).to be true
      end
    end

    context "when variant has purchases" do
      let(:supplier) { create(:supplier) }

      before do
        Purchase.create!(product: product, variant: variant, supplier: supplier, amount: 1, item_price: 10)
      end

      it "returns true" do
        expect(variant.has_sales_or_purchases?).to be true
      end
    end
  end

  describe ".active scope" do
    let!(:active_variant) { create(:product).base_variant }
    let!(:deactivated_variant) { create(:product).base_variant.tap { |variant| variant.update!(deactivated_at: Time.current) } }

    it "includes active variants" do
      expect(described_class.active).to include(active_variant)
    end

    it "excludes deactivated variants" do
      expect(described_class.active).not_to include(deactivated_variant)
    end
  end

  describe ".deactivated scope" do
    let!(:active_variant) { create(:product).base_variant }
    let!(:deactivated_variant) { create(:product).base_variant.tap { |variant| variant.update!(deactivated_at: Time.current) } }

    it "includes deactivated variants" do
      expect(described_class.deactivated).to include(deactivated_variant)
    end

    it "excludes active variants" do
      expect(described_class.deactivated).not_to include(active_variant)
    end
  end
end
