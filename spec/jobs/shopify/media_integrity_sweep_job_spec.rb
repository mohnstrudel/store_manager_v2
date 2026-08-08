# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::MediaIntegritySweepJob do
  include ActiveJob::TestHelper

  def attach_variant_record(blob, digest: SecureRandom.hex(8))
    variant_record = blob.variant_records.create!(variation_digest: digest)
    variant_record.image.attach(
      io: StringIO.new("variant data"),
      filename: "thumb.webp",
      content_type: "image/webp"
    )
    variant_record
  end

  describe "#perform" do
    it "takes no action when the original blob and all variant records exist in storage" do
      media = create(:media, :for_product)
      variant_record = attach_variant_record(media.image.blob)

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(Shopify::PullProductJob)

      expect(ActiveStorage::VariantRecord.exists?(variant_record.id)).to be true
    end

    it "enqueues exactly one Shopify::PullProductJob when the original blob is missing" do
      product = create(:product, shopify_store_id: "gid://shopify/Product/999")
      media = create(:media, :for_product, mediaable: product)
      media.image.blob.service.delete(media.image.blob.key)

      expect {
        described_class.new.perform
      }.to have_enqueued_job(Shopify::PullProductJob).with("gid://shopify/Product/999").exactly(:once)
    end

    it "enqueues one Shopify::PullProductJob, not two, when two media on the same product are broken" do
      product = create(:product, shopify_store_id: "gid://shopify/Product/999")
      media_a = create(:media, :for_product, mediaable: product)
      media_b = create(:media, :for_product, mediaable: product)
      media_a.image.blob.service.delete(media_a.image.blob.key)
      media_b.image.blob.service.delete(media_b.image.blob.key)

      expect {
        described_class.new.perform
      }.to have_enqueued_job(Shopify::PullProductJob).exactly(:once)
    end

    it "destroys a missing variant record and enqueues no PullProductJob when the original is intact" do
      media = create(:media, :for_product)
      variant_record = attach_variant_record(media.image.blob)
      variant_record.image.blob.service.delete(variant_record.image.blob.key)

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(Shopify::PullProductJob)

      expect(ActiveStorage::VariantRecord.exists?(variant_record.id)).to be false
    end

    it "skips a broken Media owned by a Warehouse without error" do
      media = create(:media, :for_warehouse)
      media.image.blob.service.delete(media.image.blob.key)

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(Shopify::PullProductJob)
    end

    it "skips a broken Media owned by a PurchaseItem without error" do
      media = create(:media, :for_purchase_item)
      media.image.blob.service.delete(media.image.blob.key)

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(Shopify::PullProductJob)
    end

    it "skips a broken Media on a Product with a blank shopify_store_id without error" do
      product = create(:product, shopify_store_id: "")
      media = create(:media, :for_product, mediaable: product)
      media.image.blob.service.delete(media.image.blob.key)

      expect {
        described_class.new.perform
      }.not_to have_enqueued_job(Shopify::PullProductJob)
    end

    it "skips a Media whose service.exist? raises and still processes the rest of the batch" do
      product = create(:product, shopify_store_id: "gid://shopify/Product/999")
      failing_media = create(:media, :for_product)
      healthy_media = create(:media, :for_product, mediaable: product)
      healthy_media.image.blob.service.delete(healthy_media.image.blob.key)
      failing_key = failing_media.image.blob.key

      real_service = failing_media.image.blob.service
      allow(real_service).to receive(:exist?).and_wrap_original do |method, key|
        key == failing_key ? raise(Timeout::Error, "R2 unavailable") : method.call(key)
      end

      expect {
        described_class.new.perform
      }.to have_enqueued_job(Shopify::PullProductJob).with("gid://shopify/Product/999").exactly(:once)
    end
  end
end
