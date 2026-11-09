# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Pull, :aggregate_failures do
  let(:api_client) { instance_double(Shopify::Api::Client) }
  let(:invalid_product) do
    {store_id: "gid://shopify/Product/1", store_link: "nameless", title: "", franchise: "Elden Ring", shape: "Statue", sku: "nameless-001", tags: []}
  end
  let(:valid_product) do
    {store_id: "gid://shopify/Product/2", store_link: "malenia", title: "Malenia", franchise: "Elden Ring", shape: "Statue", sku: "malenia-001", tags: []}
  end
  let(:payload) do
    {items: [{"id" => "gid://shopify/Product/1"}, {"id" => "gid://shopify/Product/2"}], has_next_page: true, end_cursor: "next"}
  end

  before do
    allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
    allow(api_client).to receive(:fetch_products).and_return(payload)
    allow(Product::Shopify::Parser).to receive(:parse) do |item|
      [invalid_product, valid_product].find { |parsed| parsed[:store_id] == item["id"] }
    end
  end

  it "records a product that fails validation as a page failure and imports the rest of the page" do
    freeze_time do
      page = described_class.page

      expect(Product.find_by_shopify_id("gid://shopify/Product/2")).to be_present
      expect(Product.find_by_shopify_id("gid://shopify/Product/1")).to be_nil
      expect(page).to have_attributes(
        imported_count: 1,
        next_cursor: "next",
        failures: [Shopify::Pull::Failure.new(
          store_id: "gid://shopify/Product/1",
          message: "Failed to process Product: Title can't be blank",
          failed_at: Time.current
        )]
      )
    end
  end

  it "fetches a full page of products changed since the given time" do
    updated_since = Time.zone.local(2026, 11, 10, 9, 45)

    described_class.page(cursor: "abc", updated_since:)

    expect(api_client).to have_received(:fetch_products).with(cursor: "abc", batch_size: 250, updated_since:)
  end

  it "queues each product's media import without forcing it" do
    media = [{key: "gid://shopify/MediaImage/1", id: "gid://shopify/MediaImage/1", url: "https://cdn.example.com/a.jpg", alt: "", position: 0}]
    allow(Shopify::ImportMediaJob).to receive(:perform_later)
    allow(Product::Shopify::Parser).to receive(:parse).and_return(valid_product.merge(media:))
    allow(api_client).to receive(:fetch_products).and_return(payload.merge(items: [{"id" => "gid://shopify/Product/2"}]))

    described_class.page

    expect(Shopify::ImportMediaJob).to have_received(:perform_later)
      .with(Product.find_by_shopify_id("gid://shopify/Product/2"), media, force: false)
  end

  it "stops the page on an error that is not an item failure" do
    allow(Product::Shopify::Importer).to receive(:import).and_raise("boom")

    expect { described_class.page }.to raise_error(RuntimeError, "boom")
  end
end
