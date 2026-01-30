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
    it "processes each edition using EditionCreator" do # rubocop:todo RSpec/MultipleExpectations
      edition_creator_class_double = class_double(Shopify::EditionCreator)
      edition_creator_instance_double = instance_double(Shopify::EditionCreator)
      edition = instance_double(Edition)

      stub_const("Shopify::EditionCreator", edition_creator_class_double)

      allow(edition_creator_class_double).to receive(:new)
        .with(product, parsed_editions.first)
        .and_return(edition_creator_instance_double)
      allow(edition_creator_instance_double).to receive(:update_or_create!).and_return(edition)

      job.perform(product, parsed_editions)

      expect(edition_creator_class_double).to have_received(:new)
        .with(product, parsed_editions.first)
      expect(edition_creator_instance_double).to have_received(:update_or_create!)
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

      allow(Shopify::EditionCreator).to receive(:new).and_call_original
      allow(Shopify::EditionCreator).to receive(:new).with(product, kind_of(Hash)).and_call_original

      expect {
        job.perform(product, multiple_editions)
      }.to change(product.editions, :count).by_at_least(1)
    end
  end
end
