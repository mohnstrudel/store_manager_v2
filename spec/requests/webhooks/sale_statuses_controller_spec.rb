# frozen_string_literal: true

require "rails_helper"

RSpec.describe Webhooks::SaleStatusesController do
  let(:json_headers) { {"CONTENT_TYPE" => "application/json"} }

  def post_sale_status(body)
    post "/sale-status", params: body.to_json, headers: json_headers
  end

  def parsed_response
    JSON.parse(response.body, symbolize_names: true)
  end

  describe "POST /sale-status" do
    context "when the order exists with a tracked item" do
      let(:warehouse) { create(:warehouse, external_name_de: "Im Zulauf", desc_de: "Ware unterwegs") }
      let(:sale) { create(:sale, shopify_name: "HSCM#1001") }

      before do
        sale_item = create(:sale_item, sale:)
        create(:purchase_item, warehouse:, sale_item:)

        post_sale_status({orderIdentifier: "HSCM#1001"})
      end

      it { expect(response).to have_http_status(:ok) }

      it "returns an array of tracking items with the expected contract" do
        items = parsed_response

        aggregate_failures do
          expect(items).to be_an(Array)
          expect(items.first).to include(
            productName: sale_item_title(sale),
            status: "Im Zulauf",
            description: "Ware unterwegs"
          )
        end
      end
    end

    context "when orderIdentifier is missing" do
      before { post_sale_status({}) }

      it { expect(response).to have_http_status(:bad_request) }
      it { expect(parsed_response[:error]).to eq("Order identifier is required") }
    end

    context "when the order is not found" do
      before { post_sale_status({orderIdentifier: "HSCM#9999"}) }

      it { expect(response).to have_http_status(:not_found) }
      it { expect(parsed_response[:error]).to include("not found") }
    end
  end

  def sale_item_title(sale)
    sale.sale_items.first.title
  end
end
