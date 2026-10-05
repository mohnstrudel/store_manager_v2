# frozen_string_literal: true

require "rails_helper"

RSpec.shared_examples "a normal Variant assignment" do
  it "normalizes a missing Variant to assignable Base" do
    record = build_record(product:, variant: nil)

    record.validate

    expect(record.variant).to eq(product.base_variant)
    expect(record.errors[:variant]).to be_empty
  end

  it "requires an explicit real Variant when real Variants are assignable" do
    create(:variant, product:)
    record = build_record(product:, variant: nil)

    expect(record).not_to be_valid
    expect(record.errors[:variant]).to be_present
  end

  it "accepts an assignable real Variant from the same Product" do
    variant = create(:variant, product:)

    expect(build_record(product:, variant:)).to be_valid
  end

  it "rejects a Variant from another Product" do
    foreign_variant = create(:variant)
    record = build_record(product:, variant: foreign_variant)

    expect(record).not_to be_valid
    expect(record.errors[:variant]).to be_present
  end

  it "rejects a new reference to a deactivated real Variant" do
    historical_variant = create(:variant, product:)
    historical_variant.update!(deactivated_at: Time.current)
    record = build_record(product:, variant: historical_variant)

    expect(record).not_to be_valid
    expect(record.errors[:variant]).to be_present
  end

  it "preserves an unchanged same-Product deactivated real Variant" do
    historical_variant = create(:variant, product:)
    record = create_record(product:, variant: historical_variant)
    historical_variant.update!(deactivated_at: Time.current)

    change_unrelated_attribute(record)

    expect(record).to be_valid
  end

  let(:product) { create(:product) }
end

RSpec.describe "Variant assignment" do
  describe Purchase do
    it_behaves_like "a normal Variant assignment" do
      def build_record(product:, variant:)
        build(:purchase, product:, variant:, supplier: create(:supplier))
      end

      def create_record(product:, variant:)
        create(:purchase, product:, variant:)
      end

      def change_unrelated_attribute(record)
        record.order_reference = "updated-reference"
      end
    end
  end

  describe SaleItem do
    it_behaves_like "a normal Variant assignment" do
      def build_record(product:, variant:)
        build(:sale_item, product:, variant:)
      end

      def create_record(product:, variant:)
        create(:sale_item, product:, variant:)
      end

      def change_unrelated_attribute(record)
        record.price = BigDecimal(900)
      end
    end
  end
end
