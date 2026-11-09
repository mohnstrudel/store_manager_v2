# frozen_string_literal: true

require "rails_helper"

RSpec.describe Webhooks::OrderUpdatesController do
  let(:request_body) {
    file_fixture("api_hooks_order.json").read
  }
  let(:parsed_order) {
    JSON.parse(file_fixture("parsed_hooks_order.json").read, symbolize_names: true)
  }

  it "rejects a payload with a wrong signature without importing it" do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("WOO_WEBHOOK_SECRET").and_return("order-secret")

    expect {
      post "/update-order", params: request_body, headers: {"CONTENT_TYPE" => "application/json", "x-wc-webhook-signature" => "wrong"}
    }.not_to change(Sale, :count)

    expect(response).to have_http_status(:unauthorized)
  end

  context "when a line fails validation" do
    let(:payload) do
      JSON.parse(request_body, symbolize_names: true).tap do |order|
        order[:line_items] = [order[:line_items].first.merge(meta_data: [])]
      end
    end
    let(:product) { create(:product, woo_store_id: payload[:line_items].first[:product_id].to_s) }
    let(:sale) { create(:sale, woo_store_id: payload[:id].to_s, status: "processing") }

    before do
      create(:exchange_rate, date: Date.new(2000, 1, 1), currency: "USD", rate: BigDecimal("1.1250"))
      variant = create(:variant, :with_version, product:)
      sale_item = create(:sale_item, product:, sale:, variant:, woo_store_id: payload[:line_items].first[:id].to_s)
      sale_item.update_column(:variant_id, nil) # rubocop:disable Rails/SkipsModelValidations
      allow_any_instance_of(described_class).to receive(:verify_webhook).and_return(true)
    end

    it "writes no import failure" do
      expect {
        post "/update-order", params: payload.to_json, headers: {"CONTENT_TYPE" => "application/json"}
      }.not_to change(Sale::ImportFailure, :count)
    end

    it "responds with a server error and rolls the order back", :aggregate_failures do
      post "/update-order", params: payload.to_json, headers: {"CONTENT_TYPE" => "application/json"}

      expect(response).to have_http_status(:internal_server_error)
      expect(sale.reload.status).to eq("processing")
    end
  end

  context "when a line is skipped because its product was not found" do
    let(:payload) do
      JSON.parse(request_body, symbolize_names: true).tap do |order|
        order[:line_items] = [order[:line_items].first]
      end
    end
    let(:line) { payload[:line_items].first }
    let(:failure) { Sale::ImportFailure.find_by!(store_name: "woo", store_order_id: payload[:id].to_s) }

    before do
      create(:exchange_rate, date: Date.new(2000, 1, 1), currency: "USD", rate: BigDecimal("1.1250"))
      allow_any_instance_of(described_class).to receive(:verify_webhook).and_return(true)
      allow(Product::Woo::Importer).to receive(:fetch_and_import).and_return(nil)
      post "/update-order", params: payload.to_json, headers: {"CONTENT_TYPE" => "application/json"}
    end

    it "saves the order and records the skipped line", :aggregate_failures do
      expect(response).to have_http_status(:no_content)
      expect(failure).to have_attributes(
        message: "Woo line #{line[:id]} (Woo product #{line[:product_id]}): product not found",
        sentry_event_id: nil,
        resolved_at: nil,
        sale: Sale.find_by_woo_id(payload[:id])
      )
    end

    it "resolves the failure when a later delivery imports the line" do
      product = create(:product, woo_store_id: line[:product_id].to_s)
      create(:variant, :with_version, product:)

      post "/update-order", params: payload.to_json, headers: {"CONTENT_TYPE" => "application/json"}

      expect(failure.resolved_at).to be_present
    end
  end

  # rubocop:disable RSpec/ExampleLength
  describe "when we receive a payload from Webhook" do
    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("WOO_WEBHOOK_SECRET").and_return("order-secret")
      create(:exchange_rate, date: Date.new(2000, 1, 1), currency: "USD", rate: BigDecimal("1.1250"))
      customer = create(:customer, :synced, woo_id: parsed_order[:customer][:woo_id])
      sale = create(:sale, :synced, woo_id: parsed_order[:sale][:woo_id], customer:)
      product = create(:product, :synced, woo_id: parsed_order[:products].first[:product_woo_id])
      variant = create(:variant, :synced, woo_id: parsed_order[:products].first[:variant][:woo_id], product:)
      @sale_item = create(
        :sale_item, :synced,
        sale:,
        product:,
        variant:,
        qty: 666,
        price: 666,
        woo_id: parsed_order[:products].first[:order_woo_id]
      )

      allow_any_instance_of(described_class).to receive(:verify_webhook).and_return(true)
      Sale::ImportFailure.record(store_name: "woo", store_order_id: parsed_order[:sale][:woo_id], message: "boom", sentry_event_id: nil, failed_at: 1.hour.ago)

      post "/update-order", params: request_body, headers: {"CONTENT_TYPE" => "application/json"}
    end

    it "resolves the order's import failure" do
      expect(Sale::ImportFailure.find_by!(store_name: "woo", store_order_id: parsed_order[:sale][:woo_id]).resolved_at).to be_present
    end

    it "updates a product sale related to the parsed product" do # rubocop:todo RSpec/MultipleExpectations
      parsed_product = parsed_order[:products].first
      updated_sale_item = SaleItem.find(@sale_item.id) # rubocop:todo RSpec/InstanceVariable

      expect(updated_sale_item.qty).to eq(parsed_product[:qty])
      expect(updated_sale_item.price).to eq(
        BigDecimal(parsed_product[:price])
      )
      expect(updated_sale_item.variant.title).to eq(
        parsed_product[:variant][:display_value]
      )
    end

    it "creates a new sale when it doesn't exist" do # rubocop:todo RSpec/MultipleExpectations
      parsed_product = parsed_order[:products].last
      new_sale = SaleItem.last

      expect(new_sale.qty).to eq(parsed_product[:qty])
      expect(new_sale.price).to eq(
        BigDecimal(parsed_product[:price])
      )
      expect(new_sale.variant.title).to eq(
        parsed_product[:variant][:display_value]
      )
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
