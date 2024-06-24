require "rails_helper"

RSpec.describe WebhookController do
  let(:request_body) {
    file_fixture("api_hooks_order.json").read
  }
  let(:parsed_order) {
    JSON.parse(file_fixture("parsed_hooks_order.json").read, symbolize_names: true)
  }

  # rubocop:disable RSpec/ExampleLength
  describe "when we receive a payload from Webhook" do
    before do
      customer = create(:customer, woo_id: parsed_order[:customer][:woo_id])
      sale = create(:sale, woo_id: parsed_order[:sale][:woo_id], customer:)
      product = create(:product, woo_id: parsed_order[:products].first[:product_woo_id])
      variation = create(:variation, woo_id: parsed_order[:products].first[:variation][:woo_id], product:)
      @product_sale = create(
        :product_sale,
        sale:,
        product:,
        variation:,
        qty: 666,
        price: 666,
        woo_id: parsed_order[:products].first[:order_woo_id]
      )

      allow_any_instance_of(described_class).to receive(:verify_webhook).and_return(true)

      post "/update-order", params: request_body, headers: {"CONTENT_TYPE" => "application/json"}
    end

    it "updates a product sale related to the parsed product" do
      parsed_product = parsed_order[:products].first
      updated_product_sale = ProductSale.find(@product_sale.id)

      expect(updated_product_sale.qty).to eq(parsed_product[:qty])
      expect(updated_product_sale.price).to eq(
        BigDecimal(parsed_product[:price])
      )
      expect(updated_product_sale.variation.title).to eq(
        parsed_product[:variation][:display_value]
      )
    end

    it "creates a new sale when it doesn't exist" do
      parsed_product = parsed_order[:products].last
      new_sale = ProductSale.last

      expect(new_sale.qty).to eq(parsed_product[:qty])
      expect(new_sale.price).to eq(
        BigDecimal(parsed_product[:price])
      )
      expect(new_sale.variation.title).to eq(
        parsed_product[:variation][:display_value]
      )
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
