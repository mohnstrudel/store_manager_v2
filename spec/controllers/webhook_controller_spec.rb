require "rails_helper"

RSpec.describe WebhookController do
  let(:req) {
    file_fixture("api_hooks_order.json").read
  }
  let(:parsed_order) {
    JSON.parse(file_fixture("parsed_hooks_order.json").read, symbolize_names: true)
  }

  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe "#verify_webhook" do
    let(:invalid_signature) { "invalid_signature" }
    let(:secret) { "my_secret" }
    let(:payload) { "test_payload" }
    let(:valid_signature) do
      Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, payload))
    end

    before do
      request.headers["x-wc-webhook-signature"] = valid_signature
      allow(request).to receive(:body).and_return(StringIO.new(payload))
    end

    it "returns true when the signature is valid" do
      expect(subject.send(:verify_webhook, secret)).to be_truthy
    end

    it "returns false when the signature is invalid" do
      request.headers["x-wc-webhook-signature"] = invalid_signature
      expect(subject.send(:verify_webhook, secret)).to be_falsy
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers

  describe "#update_sale" do
    let(:customer_id) {
      subject.send(:update_customer, parsed_order[:customer])
    }

    it "returns a sale object" do
      sale_payload = parsed_order[:sale].merge({customer_id:})
      sale = subject.send(:update_sale, sale_payload)

      expect(sale).to be_a(Sale)
    end

    it "reuses the same sale object" do
      sale_payload = parsed_order[:sale].merge({customer_id:})
      existing_sale = create(:sale, woo_id: sale_payload[:woo_id])
      sale = subject.send(:update_sale, sale_payload)

      expect(sale.woo_id).to eq(existing_sale.woo_id)
      expect(sale.id).to eq(existing_sale.id)
    end
  end

  # rubocop:disable RSpec/ExampleLength
  describe "#update_parsed_product" do
    it "updates a product sale related to the parsed product" do
      customer = create(:customer, woo_id: "4")
      sale = create(:sale, woo_id: "24263", customer:)
      product = create(:product, woo_id: "11")
      variation = create(:variation, woo_id: "1111", product:)
      product_sale = create(
        :product_sale,
        sale:,
        product:,
        variation:,
        qty: 666,
        price: 666,
        woo_id: 7449
      )
      parsed_product = parsed_order[:products].find { |el|
        el[:product_woo_id] == 11
      }

      subject.send(:update_parsed_product, parsed_product, sale)

      expect(ProductSale.find(product_sale.id).qty).to eq(1)
      expect(ProductSale.find(product_sale.id).price).to eq(BigDecimal("235"))
    end
  end
  # rubocop:enable RSpec/ExampleLength
end
