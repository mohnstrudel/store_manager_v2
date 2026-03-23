# frozen_string_literal: true

# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  full_title   :string
#  image        :string
#  sku          :string
#  slug         :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  franchise_id :bigint           not null
#  shape_id     :bigint           not null
#  shopify_id   :string
#  woo_id       :string
#
require "rails_helper"

RSpec.describe Product do
  subject(:product) { build(:product) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:sku) }

    it "enforces sku uniqueness" do
      existing_product = create(:product, sku: "SKU-123")
      duplicate_product = build(:product, sku: existing_product.sku)

      expect(duplicate_product).not_to be_valid
      expect(duplicate_product.errors[:sku]).to include("has already been taken")
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:franchise) }
    it { is_expected.to belong_to(:shape) }

    it { is_expected.to have_many(:editions).dependent(:destroy).autosave(true).inverse_of(:product) }
    it { is_expected.to have_many(:product_brands).dependent(:destroy).inverse_of(:product) }
    it { is_expected.to have_many(:brands).through(:product_brands) }
    it { is_expected.to have_many(:product_sizes).dependent(:destroy).inverse_of(:product) }
    it { is_expected.to have_many(:sizes).through(:product_sizes) }
    it { is_expected.to have_many(:product_versions).dependent(:destroy).inverse_of(:product) }
    it { is_expected.to have_many(:versions).through(:product_versions) }
    it { is_expected.to have_many(:product_colors).dependent(:destroy).inverse_of(:product) }
    it { is_expected.to have_many(:colors).through(:product_colors) }
    it { is_expected.to have_many(:sale_items).dependent(:destroy).inverse_of(:product) }
    it { is_expected.to have_many(:sales).through(:sale_items) }
    it { is_expected.to have_many(:purchases).dependent(:destroy).inverse_of(:product) }
    it { is_expected.to have_many(:purchase_items).through(:purchases) }
    it { is_expected.to have_rich_text(:description) }
    it { is_expected.to accept_nested_attributes_for(:purchases) }
  end

  describe "configuration and extensions" do
    it "is audited and tied to franchise" do
      aggregate_failures do
        expect(described_class.auditing_enabled).to be true
        expect(described_class.audit_associated_with).to eq(:franchise)
      end
    end

    it "has associated audits" do
      expect(described_class.instance_methods).to include(:associated_audits)
    end

    it "configures FriendlyId on the title candidate" do
      expect(described_class.friendly_id_config.base).to eq(:find_slug_candidate)
    end

    it "paginates 50 records per page" do
      expect(described_class.default_per_page).to eq(50)
    end

    it "exposes the search scopes" do
      aggregate_failures do
        expect(described_class).to respond_to(:search)
        expect(described_class).to respond_to(:search_by)
      end
    end
  end

  describe "callbacks" do
    it "sets full_title after create" do
      product = create(:product)

      expect(product.full_title).to eq("Studio Ghibli — Spirited Away")
    end
  end
end
