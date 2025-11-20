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
      edition = create(:edition, woo_id: parsed_order[:products].first[:edition][:woo_id], product:)
      @sale_item = create(
        :sale_item,
        sale:,
        product:,
        edition:,
        qty: 666,
        price: 666,
        woo_id: parsed_order[:products].first[:order_woo_id]
      )

      # rubocop:todo RSpec/AnyInstance
      allow_any_instance_of(described_class).to receive(:verify_webhook).and_return(true)
      # rubocop:enable RSpec/AnyInstance

      post "/update-order", params: request_body, headers: {"CONTENT_TYPE" => "application/json"}
    end

    it "updates a product sale related to the parsed product" do # rubocop:todo RSpec/MultipleExpectations
      parsed_product = parsed_order[:products].first
      updated_sale_item = SaleItem.find(@sale_item.id) # rubocop:todo RSpec/InstanceVariable

      expect(updated_sale_item.qty).to eq(parsed_product[:qty])
      expect(updated_sale_item.price).to eq(
        BigDecimal(parsed_product[:price])
      )
      expect(updated_sale_item.edition.title).to eq(
        parsed_product[:edition][:display_value]
      )
    end

    it "creates a new sale when it doesn't exist" do # rubocop:todo RSpec/MultipleExpectations
      parsed_product = parsed_order[:products].last
      new_sale = SaleItem.last

      expect(new_sale.qty).to eq(parsed_product[:qty])
      expect(new_sale.price).to eq(
        BigDecimal(parsed_product[:price])
      )
      expect(new_sale.edition.title).to eq(
        parsed_product[:edition][:display_value]
      )
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
