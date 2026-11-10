# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::Pull, :aggregate_failures do
  let(:skippable_error) { Class.new(StandardError) }
  let(:importer) { class_double(Sale::Shopify::Importer, import: true) }
  let(:parser) { class_double(Sale::Shopify::Parser) }
  let(:api_client) { instance_double(Shopify::Api::Client) }
  let(:payload) { {items: [{"id" => "gid://1"}, {"id" => "gid://2"}], has_next_page: false, end_cursor: "end"} }
  let(:pull_class) do
    importer = self.importer
    parser = self.parser
    skippable_error = self.skippable_error

    Class.new(described_class) do
      define_method(:fetch) do |api_client, cursor:, batch_size:, updated_since:|
        api_client.fetch_orders(cursor:, batch_size:, updated_since:)
      end
      define_method(:batch_size) { 10 }
      define_method(:importer_class) { importer }
      define_method(:parser_class) { parser }
      define_method(:skippable_errors) { [skippable_error] }
    end
  end

  before do
    allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
    allow(api_client).to receive(:fetch_orders).and_return(payload)
    allow(parser).to receive(:parse) { |item| {store_id: item["id"]} }
  end

  it "fetches one unfiltered page with the default batch size and imports every parsed item" do
    page = pull_class.page

    expect(api_client).to have_received(:fetch_orders).with(cursor: nil, batch_size: 10, updated_since: nil)
    expect(importer).to have_received(:import).with({store_id: "gid://1"})
    expect(importer).to have_received(:import).with({store_id: "gid://2"})
    expect(page).to have_attributes(imported_count: 2, next_cursor: nil, failures: [])
  end

  it "fetches the given cursor and updated_since with the default batch size" do
    updated_since = Time.zone.local(2026, 11, 10, 9, 45)

    pull_class.page(cursor: "abc", updated_since:)

    expect(api_client).to have_received(:fetch_orders).with(cursor: "abc", batch_size: 10, updated_since:)
  end

  it "returns the end cursor only when Shopify reports another page" do
    payload[:has_next_page] = true

    expect(pull_class.page.next_cursor).to eq("end")
  end

  it "collects skippable item failures and keeps importing the rest of the page" do
    allow(importer).to receive(:import).with({store_id: "gid://1"}).and_raise(skippable_error, "Variant must be selected")

    freeze_time do
      page = pull_class.page

      expect(importer).to have_received(:import).with({store_id: "gid://2"})
      expect(page.imported_count).to eq(1)
      expect(page.failures).to eq([described_class::Failure.new(store_id: "gid://1", message: "Variant must be selected", failed_at: Time.current)])
    end
  end

  it "raises other import errors" do
    allow(importer).to receive(:import).and_raise("Sku has already been taken")

    expect { pull_class.page }.to raise_error(RuntimeError, /already been taken/)
  end

  describe Shopify::Pull::Failed do
    it "describes at most the first ten failures" do
      failures = Array.new(12) { |index| Shopify::Pull::Failure.new(store_id: "gid://#{index}", message: "boom #{index}", failed_at: Time.current) }

      error = described_class.new(failures)

      expect(error.failures).to eq(failures)
      expect(error.message).to start_with("12 Shopify item(s) failed to import: gid://0: boom 0; ")
      expect(error.message).to include("gid://9: boom 9")
      expect(error.message).not_to include("gid://10")
    end

    it "counts the failures it lists unless told how many the whole pull had" do
      failures = [Shopify::Pull::Failure.new(store_id: "gid://1", message: "boom", failed_at: Time.current)]

      expect(described_class.new(failures).message).to start_with("1 Shopify item(s) failed to import: gid://1: boom")
      expect(described_class.new(failures, total: 7).message).to start_with("7 Shopify item(s) failed to import: gid://1: boom")
    end
  end
end
