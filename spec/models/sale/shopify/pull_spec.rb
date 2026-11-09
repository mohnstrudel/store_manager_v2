# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Shopify::Pull, :aggregate_failures do
  let(:api_client) { instance_double(Shopify::Api::Client) }
  let(:payload) do
    {items: [{"id" => "gid://shopify/Order/1"}, {"id" => "gid://shopify/Order/2"}], has_next_page: true, end_cursor: "next"}
  end

  before do
    allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
    allow(api_client).to receive(:fetch_orders).and_return(payload)
    allow(Sale::Shopify::Parser).to receive(:parse) { |item| {store_id: item["id"]} }
    allow(Sale::Shopify::Importer).to receive(:import)
  end

  [Sale::Shopify::Importer::Error, Customer::Shopify::Importer::Error].each do |error_class|
    it "records #{error_class} as a page failure for that order and imports the rest of the page" do
      allow(Sale::Shopify::Importer).to receive(:import)
        .with({store_id: "gid://shopify/Order/1"})
        .and_raise(error_class, "Failed to process Customer: Customer must have contact details or store information")

      freeze_time do
        page = described_class.page

        expect(Sale::Shopify::Importer).to have_received(:import).with({store_id: "gid://shopify/Order/2"})
        expect(page).to have_attributes(
          imported_count: 1,
          next_cursor: "next",
          failures: [Shopify::Pull::Failure.new(
            store_id: "gid://shopify/Order/1",
            message: "Failed to process Customer: Customer must have contact details or store information",
            failed_at: Time.current
          )]
        )
      end
    end
  end

  it "stops the page on an error that is not an item failure" do
    allow(Sale::Shopify::Importer).to receive(:import).and_raise("boom")

    expect { described_class.page }.to raise_error(RuntimeError, "boom")
  end
end
