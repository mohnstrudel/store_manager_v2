# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::InstallmentBackfill do
  describe ".call" do
    context "when the placeholder product does not exist locally" do
      it "does nothing" do
        result = described_class.call

        expect(result.reassigned_count).to eq(0)
        expect(result.unresolved_sale_item_ids).to eq([])
      end
    end

    context "when the placeholder product exists" do
      let(:placeholder_product) do
        create(:product, shopify_id: described_class::PLACEHOLDER_SHOPIFY_ID, title: "Teilzahlung / Partial Payment")
      end
      let(:customer) { create(:customer) }
      let(:real_product) { create(:product, title: "Astarion") }
      let(:origin_sale) { create(:sale, customer:) }
      let!(:origin_sale_item) { create(:sale_item, sale: origin_sale, product: real_product) }

      let(:installment_sale) { create(:sale, customer:) }
      let!(:installment_sale_item) { create(:sale_item, sale: installment_sale, product: placeholder_product) }

      it "flags the placeholder product as non_catalog and renames it" do
        described_class.call

        expect(placeholder_product.reload).to have_attributes(
          non_catalog: true,
          title: described_class::PLACEHOLDER_TITLE
        )
      end

      it "reassigns resolvable sale items to the real product and links the origin sale item" do
        result = described_class.call

        expect(installment_sale_item.reload).to have_attributes(
          product: real_product,
          origin_sale_item: origin_sale_item
        )
        expect(result.reassigned_count).to eq(1)
        expect(result.unresolved_sale_item_ids).to eq([])
      end

      context "when a sale item can't be resolved" do
        let(:origin_sale_item) { nil }
        let(:seal_client) { instance_double(Seal::Api::Client, find_subscription_for_order: nil) }

        before { allow(Seal::Api::Client).to receive(:shared).and_return(seal_client) }

        it "leaves it on the placeholder product and reports it as unresolved" do
          result = described_class.call

          expect(installment_sale_item.reload.product).to eq(placeholder_product)
          expect(result.unresolved_sale_item_ids).to eq([installment_sale_item.id])
        end
      end
    end
  end
end
