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
    it "processes each variant using Variant::Shopify::Importer" do # rubocop:todo RSpec/MultipleExpectations
      importer_class = Variant::Shopify::Importer
      variant = instance_double(Variant)

      allow(importer_class).to receive(:import!)
        .with(product, parsed_variants.first)
        .and_return(variant)

      job.perform(product, parsed_variants)

      expect(importer_class).to have_received(:import!)
        .with(product, parsed_variants.first)
    end

    it "creates variants from parsed data" do
      expect {
        job.perform(product, parsed_variants)
      }.to change(product.variants, :count).by(1)
    end

    it "updates the pull_time on shopify_info" do
      shopify_id = parsed_variants.first[:store_id]
      variant = create(:variant, product:)
      # Variant factory auto-creates store_infos, just update the shopify one
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
  end
end
