# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullVariantsJob do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:job) { described_class.new }
  let(:product) { create(:product) }
  let(:parsed_variants) do
    [
      {
        store_id: "gid://shopify/ProductVariant/12345",
        title: "Red / Large / Deluxe",
        options: [
          {value: "Red", name: "Color"},
          {value: "Large", name: "Size"},
          {value: "Deluxe", name: "Variant"}
        ]
      }
    ]
  end

  describe ".queue_as" do
    it "enqueues on the default queue" do
      expect {
        described_class.perform_later(product, parsed_variants)
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end

  describe ".perform_later" do
    it "enqueues the job" do
      expect {
        described_class.perform_later(product, parsed_variants)
      }.to have_enqueued_job(described_class)
    end
  end

  describe "#perform" do
    it "creates variants from parsed data" do
      expect {
        job.perform(product, parsed_variants)
      }.to change(product.variants, :count).by(1)
    end

    it "updates the pull_time on shopify_info" do
      shopify_id = parsed_variants.first[:store_id]
      variant = create(:variant, product:)
      variant.store_infos.shopify.first.update(store_id: shopify_id)

      freeze_time do
        job.perform(product, parsed_variants)
        expect(variant.store_infos.shopify.first.pull_time).to eq(Time.zone.now)
      end
    end

    it "processes multiple variants" do
      multiple_variants = parsed_variants * 3

      allow(Variant::Shopify::Importer).to receive(:import!).and_call_original

      expect {
        job.perform(product, multiple_variants)
      }.to change(product.variants, :count).by_at_least(1)
    end

    it "re-raises SKU collision errors" do
      allow(Variant::Shopify::Importer).to receive(:import!).and_raise(
        ActiveRecord::RecordInvalid.new(Variant.new.tap { |variant| variant.errors.add(:sku, "has already been taken") })
      )

      expect {
        job.perform(product, parsed_variants)
      }.to raise_error(StandardError) { |error|
        expect(error.message).to include("Validation failed: Sku has already been taken")
        expect(error.message).to include("product_id: #{product.id}")
        expect(error.message).to include("product_shopify_id: #{product.shopify_info.store_id}")
        expect(error.message).to include("variant_store_id: gid://shopify/ProductVariant/12345")
        expect(error.message).to include("variant_sku: blank")
      }
    end

    it "imports a normal variant following an overflowing decoy in the same batch" do
      decoy_and_normal = [
        {
          store_id: "gid://shopify/ProductVariant/11111",
          sku: "decoy-sku",
          selling_price: "99999999.99",
          usd_conversion_rate: BigDecimal("1.146"),
          usd_conversion_date: Date.new(2026, 9, 18),
          options: [{value: "White", name: "Color"}]
        },
        {
          store_id: "gid://shopify/ProductVariant/22222",
          sku: "normal-sku",
          selling_price: "750.00",
          options: [{value: "Black", name: "Color"}]
        }
      ]

      expect {
        job.perform(product, decoy_and_normal)
      }.to change(product.variants, :count).by(2)

      normal_variant = Variant.find_by_shopify_id("gid://shopify/ProductVariant/22222")
      expect(normal_variant.selling_price).to eq(BigDecimal("750.00"))
    end

    context "when two Shopify variants map to the same options" do
      let(:parsed_variants) do
        [
          {store_id: "gid://shopify/ProductVariant/1", sku: "a", options: [{name: "Edition", value: "A"}, {name: "Version", value: "A"}]},
          {store_id: "gid://shopify/ProductVariant/2", sku: "b", options: [{name: "Edition", value: "B"}, {name: "Version", value: "A"}]},
          {store_id: "gid://shopify/ProductVariant/3", sku: "c", options: [{name: "Version", value: "C"}]}
        ]
      end

      it "records the conflict and still imports the other variants" do # rubocop:todo RSpec/MultipleExpectations
        expect { job.perform(product, parsed_variants) }.not_to raise_error

        expect(VariantImportConflict.pluck(:store_id)).to eq(["gid://shopify/ProductVariant/2"])
        expect(Variant.find_by_shopify_id("gid://shopify/ProductVariant/3").version.value).to eq("C")
      end

      it "drops conflicts for Shopify variants that are no longer in the payload" do
        create(:variant_import_conflict, product:, store_id: "gid://shopify/ProductVariant/deleted")

        job.perform(product, parsed_variants)

        expect(VariantImportConflict.pluck(:store_id)).to eq(["gid://shopify/ProductVariant/2"])
      end
    end
  end
end
