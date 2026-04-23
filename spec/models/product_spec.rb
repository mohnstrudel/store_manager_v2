# frozen_string_literal: true

# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  full_title   :string
#  image        :string
#  shape        :string           default("Statue"), not null
#  slug         :string
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  franchise_id :bigint           not null
#  shopify_id   :string
#  woo_id       :string
#
require "rails_helper"

RSpec.describe Product do
  subject(:product) { build(:product) }

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:franchise) }
    it { is_expected.to validate_presence_of(:shape) }
    it { is_expected.to validate_inclusion_of(:shape).in_array(Product.shape_options) }

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

  describe "full title synchronization" do
    it "persists full_title on create" do
      product = create(:product)

      expect(product.full_title).to eq("Studio Ghibli — Spirited Away")
    end
  end

  describe "search" do
    let!(:matching_product) do
      create(:product, title: "Spirited Away", woo_id: "woo-spirited-123").tap do |product|
        size = create(:size, value: "Premium")
        version = create(:version, value: "Collector")
        color = create(:color, value: "Scarlet")

        create(:product_size, product_id: product.id, size_id: size.id)
        create(:product_version, product_id: product.id, version_id: version.id)
        create(:product_color, product_id: product.id, color_id: color.id)

        product.reload
      end
    end
    let!(:other_product) { create(:product, title: "My Neighbor Totoro", woo_id: "woo-totoro-456") }

    it "finds products by prefixes from their own and associated searchable fields" do
      aggregate_failures do
        expect(described_class.search_by("Spiri")).to include(matching_product)
        expect(described_class.search_by("woo-spir")).to include(matching_product)
        expect(described_class.search_by("Prem")).to include(matching_product)
        expect(described_class.search_by("Coll")).to include(matching_product)
        expect(described_class.search_by("Scarl")).to include(matching_product)
      end
    end

    it "returns all products when the query is blank" do
      expect(described_class.search_by("")).to contain_exactly(matching_product, other_product)
    end

    it "returns no products when nothing matches" do
      expect(described_class.search_by("nonexistent")).to be_empty
    end
  end
end
