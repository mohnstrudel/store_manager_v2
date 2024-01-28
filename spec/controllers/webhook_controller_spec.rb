require "rails_helper"

RSpec.describe WebhookController do
  let(:req) {
    file_fixture("api_hooks_order.json").read
  }
  let(:parsed_order) {
    JSON.parse(file_fixture("parsed_hooks_order.json").read, symbolize_names: true)
  }

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

  describe "#get_sale" do
    it "returns a sale object" do
      customer_payload = parsed_order[:customer]
      sale_payload = parsed_order[:sale]
      sale = subject.send(:get_sale, customer_payload, sale_payload)

      expect(sale).to be_a(Sale)
    end
  end

  describe "#get_variation_type" do
    it "returns a variation type" do
      parsed_variation = parsed_order[:products].find { |el|
        el[:variation].present?
      }[:variation]
      result = subject.send(:get_variation_type, parsed_variation)
      result_key = result.keys.first
      result_value = result.values.first

      expect(result_key).to eq("version")
      expect(result_value).to be_a(Version)
      expect(result_value[:value]).to eq("Deluxe Version")
    end
  end

  describe "#handle_parsed_product" do
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

      subject.send(:handle_parsed_product, parsed_product, sale)

      expect(ProductSale.find(product_sale.id).qty).to eq(1)
      expect(ProductSale.find(product_sale.id).price).to eq(BigDecimal("235"))
    end
  end
end
