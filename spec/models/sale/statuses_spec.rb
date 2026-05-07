# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Statuses do
  describe "#item_tracking_payload" do
    let(:sale) { create(:sale) }
    let(:warehouse) { create(:warehouse, external_name_de: "Im Zulauf", desc_de: "Ware unterwegs") }

    context "when a sale item has a linked purchase item with a warehouse" do
      before do
        sale_item = create(:sale_item, sale:)
        create(:purchase_item, warehouse:, sale_item:)
      end

      it "returns an array with status from the warehouse" do
        payload = sale.item_tracking_payload

        aggregate_failures do
          expect(payload).to be_an(Array)
          expect(payload.first[:status]).to eq("Im Zulauf")
          expect(payload.first[:description]).to eq("Ware unterwegs")
        end
      end
    end

    context "when a sale item has no linked purchase item" do
      before do
        create(:sale_item, sale:)
      end

      it "returns nil status and description" do
        payload = sale.item_tracking_payload

        aggregate_failures do
          expect(payload.first[:status]).to be_nil
          expect(payload.first[:description]).to be_nil
        end
      end
    end

    context "when there are multiple sale items" do
      before do
        2.times { create(:sale_item, sale:) }
      end

      it "returns an array" do
        expect(sale.item_tracking_payload).to be_an(Array)
      end
    end

    context "when the warehouse has no German name" do
      before do
        warehouse_en_only = create(:warehouse, external_name_de: nil, external_name_en: "In transit", desc_de: nil, desc_en: "On the way")
        sale_item = create(:sale_item, sale:)
        create(:purchase_item, warehouse: warehouse_en_only, sale_item:)
      end

      it "falls back to English names" do
        payload = sale.item_tracking_payload

        aggregate_failures do
          expect(payload.first[:status]).to eq("In transit")
          expect(payload.first[:description]).to eq("On the way")
        end
      end
    end
  end
end
