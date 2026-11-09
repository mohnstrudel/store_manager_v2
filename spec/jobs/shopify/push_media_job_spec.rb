# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PushMediaJob do
  include ActiveJob::TestHelper

  describe ".perform_later" do
    let(:shopify_product_id) { "gid://shopify/Product/123" }
    let(:product) { create(:product_with_brands) }

    it "enqueues the job with correct arguments" do
      expect {
        described_class.perform_later(shopify_product_id, product.id)
      }.to have_enqueued_job(described_class).with(shopify_product_id, product.id).exactly(:once)
    end
  end

  describe "#perform" do
    it "delegates to Product::Shopify::Media::Push" do
      allow(Product::Shopify::Media::Push).to receive(:call)

      described_class.new.perform(42, "gid://shopify/Product/123")

      expect(Product::Shopify::Media::Push).to have_received(:call).with(
        product_id: 42,
        product_store_id: "gid://shopify/Product/123"
      )
    end
  end

  describe "when the push cannot finish yet" do
    let(:not_ready) { Product::Shopify::Media::Push::NotReady.new("Shopify has not finished processing media") }

    before do
      allow(Product::Shopify::Media::Push).to receive(:call).and_raise(not_ready)
      allow(Sentry).to receive(:capture_exception)
    end

    it "retries every 10 seconds, plus the framework jitter, with the same arguments" do
      freeze_time do
        described_class.perform_now(42, "gid://shopify/Product/123")
        ActiveJob::Base.execute(enqueued_jobs.last)

        waits = enqueued_jobs.map { |job| Time.zone.at(job[:at]) - Time.current }
        expect(waits).to all(be_between(10, 10 * (1 + ActiveJob::Base.retry_jitter)))
        expect(enqueued_jobs.size).to eq(2)
        expect(enqueued_jobs.pluck(:args).uniq.size).to eq(1)
        expect(Sentry).not_to have_received(:capture_exception)
      end
    end

    it "gives up after 60 attempts, reports the last error to Sentry, and does not raise" do
      freeze_time do
        described_class.perform_now(42, "gid://shopify/Product/123")
        58.times { ActiveJob::Base.execute(enqueued_jobs.last) }
        expect(Sentry).not_to have_received(:capture_exception)

        expect { ActiveJob::Base.execute(enqueued_jobs.last) }.not_to raise_error

        expect(enqueued_jobs.size).to eq(59)
        expect(Sentry).to have_received(:capture_exception).with(not_ready).once
      end
    end
  end

  describe "when Shopify failed to process a media" do
    let(:media_failed) { Product::Shopify::Media::Push::MediaFailed.new("Shopify failed to process media") }

    before do
      allow(Product::Shopify::Media::Push).to receive(:call).and_raise(media_failed)
      allow(Sentry).to receive(:capture_exception)
    end

    it "reports to Sentry and discards without retrying" do
      expect { described_class.perform_now(42, "gid://shopify/Product/123") }.not_to raise_error

      expect(Sentry).to have_received(:capture_exception).with(media_failed).once
      expect(enqueued_jobs).to be_empty
    end
  end

  describe "when Shopify throttles the push" do
    before { allow(Product::Shopify::Media::Push).to receive(:call).and_raise(Shopify::Api::Client::Throttled) }

    it "re-enqueues the job with the same arguments" do
      expect { described_class.perform_now(42, "gid://shopify/Product/123") }
        .to have_enqueued_job(described_class).with(42, "gid://shopify/Product/123")
    end
  end
end
