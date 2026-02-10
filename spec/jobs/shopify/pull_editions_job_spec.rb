# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullEditionsJob do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:job) { described_class.new }
  let(:product) { create(:product) }
  let(:parsed_editions) do
    [
      {
        "id" => "gid://shopify/ProductVariant/12345",
        "title" => "Red / Large / Deluxe",
        "options" => [
          {"value" => "Red", "name" => "Color"},
          {"value" => "Large", "name" => "Size"},
          {"value" => "Deluxe", "name" => "Edition"}
        ]
      }
    ]
  end

  describe ".queue_as" do
    it "enqueues on the default queue" do
      expect {
        described_class.perform_later(product, parsed_editions)
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end

  describe ".perform_later" do
    it "enqueues the job" do
      expect {
        described_class.perform_later(product, parsed_editions)
      }.to have_enqueued_job(described_class)
    end
  end

  describe "#perform" do
    it "processes each edition using Edition::ShopifyImporter" do # rubocop:todo RSpec/MultipleExpectations
      importer_class = Edition::ShopifyImporter
      edition = instance_double(Edition)

      allow(importer_class).to receive(:import!)
        .with(product, parsed_editions.first)
        .and_return(edition)

      job.perform(product, parsed_editions)

      expect(importer_class).to have_received(:import!)
        .with(product, parsed_editions.first)
    end

    it "creates editions from parsed data" do
      expect {
        job.perform(product, parsed_editions)
      }.to change(product.editions, :count).by(1)
    end

    it "updates the pull_time on shopify_info" do
      shopify_id = parsed_editions.first["id"]
      edition = create(:edition, product:)
      # Edition factory auto-creates store_infos, just update the shopify one
      edition.store_infos.shopify.first.update(store_id: shopify_id)

      freeze_time do
        job.perform(product, parsed_editions)
        expect(edition.store_infos.shopify.first.pull_time).to eq(Time.zone.now)
      end
    end

    it "processes multiple editions" do
      multiple_editions = parsed_editions * 3

      allow(Edition::ShopifyImporter).to receive(:import!).and_call_original

      expect {
        job.perform(product, multiple_editions)
      }.to change(product.editions, :count).by_at_least(1)
    end
  end
end
