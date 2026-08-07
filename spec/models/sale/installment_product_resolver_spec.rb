# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::InstallmentProductResolver do
  let(:customer) { create(:customer) }
  let(:sale) { create(:sale, customer:) }
  let(:resolver) { described_class.new(sale) }

  describe "#target_product" do
    context "when the customer has exactly one other real product" do
      let(:real_product) { create(:product, title: "Astarion") }
      let(:other_sale) { create(:sale, customer:) }

      before { create(:sale_item, sale: other_sale, product: real_product) }

      it "returns that product" do
        expect(resolver.target_product).to eq(real_product)
      end
    end

    context "when the customer has no other real products" do
      it "returns nil" do
        expect(resolver.target_product).to be_nil
      end
    end

    context "when the customer has multiple real products" do
      let(:product_a) { create(:product, title: "Astarion") }
      let(:product_b) { create(:product, title: "Malenia") }
      let(:matching_sale) { create(:sale, customer:, total: sale.total) }
      let(:other_sale) { create(:sale, customer:, total: BigDecimal("9999.0")) }

      before do
        create(:sale_item, sale: matching_sale, product: product_a)
        create(:sale_item, sale: other_sale, product: product_b)
      end

      it "resolves via an exact total match against one of the customer's other orders" do
        expect(resolver.target_product).to eq(product_a)
      end

      context "when no order matches this sale's exact total" do
        let(:matching_sale) { create(:sale, customer:, total: BigDecimal("1.0")) }

        it "falls back to Seal Subscriptions" do
          seal_client = instance_double(Seal::Api::Client, find_subscription_for_order: nil)
          allow(Seal::Api::Client).to receive(:shared).and_return(seal_client)

          expect(resolver.target_product).to be_nil
          expect(seal_client).to have_received(:find_subscription_for_order)
        end
      end
    end

    context "when Seal Subscriptions resolves the product" do
      let(:real_product_store_id) { "gid://shopify/Product/777" }
      let!(:real_product) { create(:product, title: "Vegeta", shopify_id: real_product_store_id) }
      let(:subscription) { {"order_id" => "123456"} }
      let(:seal_client) { instance_double(Seal::Api::Client, find_subscription_for_order: subscription) }
      let(:origin_order) do
        {"lineItems" => {"nodes" => [{"product" => {"id" => real_product_store_id}}]}}
      end

      before do
        allow(Seal::Api::Client).to receive(:shared).and_return(seal_client)
        allow_any_instance_of(Shopify::Api::Client).to receive(:fetch_order)
          .with("gid://shopify/Order/123456").and_return(origin_order)
      end

      it "returns the product Seal identifies" do
        expect(resolver.target_product).to eq(real_product)
      end
    end

    context "when the origin order bundles multiple real products" do
      let(:product_a) { create(:product, title: "Astarion", shopify_id: "gid://shopify/Product/1") }
      let(:product_b) { create(:product, title: "Malenia", shopify_id: "gid://shopify/Product/2") }
      let(:subscription) { {"order_id" => "123456"} }
      let(:seal_client) { instance_double(Seal::Api::Client, find_subscription_for_order: subscription) }
      let(:origin_order) do
        {"lineItems" => {"nodes" => [
          {"product" => {"id" => product_a.shopify_id}},
          {"product" => {"id" => product_b.shopify_id}}
        ]}}
      end

      before do
        allow(Seal::Api::Client).to receive(:shared).and_return(seal_client)
        allow_any_instance_of(Shopify::Api::Client).to receive(:fetch_order)
          .with("gid://shopify/Order/123456").and_return(origin_order)
      end

      it "returns nil, since the payment can't be attributed to a single product" do
        expect(resolver.target_product).to be_nil
      end
    end

    context "when a Seal API error occurs" do
      let(:seal_client) { instance_double(Seal::Api::Client) }

      before do
        allow(Seal::Api::Client).to receive(:shared).and_return(seal_client)
        allow(seal_client).to receive(:find_subscription_for_order).and_raise(Seal::Api::Client::ApiError, "boom")
        allow(Sentry).to receive(:capture_exception)
      end

      it "swallows the error and returns nil" do
        expect(resolver.target_product).to be_nil
        expect(Sentry).to have_received(:capture_exception)
      end
    end
  end

  describe "#origin_sale_item" do
    context "when there is no target product" do
      it "returns nil" do
        expect(resolver.origin_sale_item).to be_nil
      end
    end

    context "when a target product is resolved" do
      let(:real_product) { create(:product, title: "Astarion") }
      let(:other_sale) { create(:sale, customer:) }
      let!(:origin_item) { create(:sale_item, sale: other_sale, product: real_product) }

      it "returns the customer's earliest non-installment sale item for that product" do
        expect(resolver.origin_sale_item).to eq(origin_item)
      end
    end
  end
end
