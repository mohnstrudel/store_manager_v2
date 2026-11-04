# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::Api::Client do
  let(:client) { described_class.new }
  let(:basic_auth) { {username: described_class::CONSUMER_KEY, password: described_class::CONSUMER_SECRET} }
  let(:json_response) { instance_double(HTTParty::Response, body: '[{"id": 1}]', code: 200, success?: true) }

  describe "#fetch_order", :vcr do
    it "replays a recorded Woo API response through VCR" do
      VCR.use_cassette("woo/api/client/fetch_order") do
        expect(client.fetch_order("123")).to eq({id: 123, status: "processing", total: "99.99"})
      end
    end
  end

  describe "#fetch_orders" do
    before do
      allow(HTTParty).to receive(:get).and_return(json_response)
    end

    it "requests one page per hundred records ordered by modification" do
      client.fetch_orders(250)

      (1..3).each do |page|
        expect(HTTParty).to have_received(:get).with(
          described_class::ORDERS_URL,
          query: {per_page: 100, page:, orderby: "modified"},
          basic_auth:
        )
      end
    end

    it "uses the provided page count instead of calculating one" do
      client.fetch_orders(250, 2)

      expect(HTTParty).to have_received(:get).twice
    end

    it "requests a single page when the total fits on one page" do
      client.fetch_orders(50)

      expect(HTTParty).to have_received(:get).once
    end

    it "flattens and compacts the pages" do
      allow(HTTParty).to receive(:get).and_return(
        instance_double(HTTParty::Response, body: '[{"id": 1}]', code: 200, success?: true),
        instance_double(HTTParty::Response, body: '[{"id": 2}, {"id": 3}]', code: 200, success?: true),
        instance_double(HTTParty::Response, body: "[]", code: 200, success?: true)
      )

      expect(client.fetch_orders(250)).to eq([{id: 1}, {id: 2}, {id: 3}])
    end
  end

  describe "#fetch_latest_orders" do
    it "requests the first page of orders ordered by modification" do
      allow(HTTParty).to receive(:get).and_return(json_response)

      expect(client.fetch_latest_orders).to eq([{id: 1}])
      expect(HTTParty).to have_received(:get).with(
        described_class::ORDERS_URL,
        query: {per_page: 100, page: 1, orderby: "modified"},
        basic_auth:
      )
    end
  end

  describe "#fetch_product" do
    it "requests one published product" do
      allow(HTTParty).to receive(:get).and_return(json_response)

      client.fetch_product(42)

      expect(HTTParty).to have_received(:get).with(
        "#{described_class::PRODUCTS_URL}42",
        query: {status: "publish"},
        basic_auth:
      )
    end
  end

  describe "#update_order_status" do
    it "posts the status with the write credentials" do
      allow(HTTParty).to receive(:post)

      client.update_order_status("4321", "completed")

      expect(HTTParty).to have_received(:post).with(
        "#{described_class::ORDERS_URL}4321",
        body: {status: "completed"},
        basic_auth: {
          username: described_class::WRITE_CONSUMER_KEY,
          password: described_class::WRITE_CONSUMER_SECRET
        }
      )
    end
  end

  describe "GET failures" do
    let(:order_url) { "#{described_class::ORDERS_URL}1" }

    before do
      allow(Rails.logger).to receive(:error)
      allow(Rails.logger).to receive(:warn)
      allow(Sentry).to receive(:capture_message)
      allow(client).to receive(:sleep)
    end

    context "when the request keeps raising" do
      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new("Network error"))
      end

      it "retries three times and returns nil" do
        expect(client.fetch_order(1)).to be_nil
        expect(HTTParty).to have_received(:get).exactly(3).times
      end

      it "logs and reports the failure after the final retry", :aggregate_failures do
        client.fetch_order(1)

        expect(Rails.logger).to have_received(:error).with("Gettable. Error: StandardError: Network error")
        expect(Sentry).to have_received(:capture_message).with(
          "Woo API GET failed after retries",
          level: :error,
          tags: {integration: "woo", concern: "Gettable"},
          extra: {
            url: order_url,
            query: {},
            error_class: "StandardError",
            error_message: "Network error",
            retries: 3
          }
        )
      end
    end

    context "when the request succeeds on a retry" do
      it "returns the parsed body" do
        call_count = 0
        allow(HTTParty).to receive(:get) do
          call_count += 1
          raise StandardError, "Failure #{call_count}" if call_count < 3

          instance_double(HTTParty::Response, body: '{"id": 1, "name": "Test"}', code: 200, success?: true)
        end

        expect(client.fetch_order(1)).to eq({id: 1, name: "Test"})
        expect(HTTParty).to have_received(:get).exactly(3).times
      end
    end

    context "when the response body is blank" do
      before do
        allow(HTTParty).to receive(:get).and_return(instance_double(HTTParty::Response, body: "", code: 200, success?: true))
      end

      it "returns nil and reports a warning", :aggregate_failures do
        expect(client.fetch_order(1)).to be_nil
        expect(Sentry).to have_received(:capture_message).with(
          "Woo API GET returned blank body",
          level: :warning,
          tags: {integration: "woo", concern: "Gettable"},
          extra: {
            url: order_url,
            query: {},
            response_class: "RSpec::Mocks::InstanceVerifyingDouble"
          }
        )
      end
    end

    context "when the response is unsuccessful" do
      before do
        allow(HTTParty).to receive(:get).and_return(
          instance_double(HTTParty::Response, body: '{"message":"Unauthorized"}', code: 401, success?: false)
        )
      end

      it "returns nil and reports the error payload", :aggregate_failures do
        expect(client.fetch_order(1)).to be_nil
        expect(Sentry).to have_received(:capture_message).with(
          "Woo API GET returned unsuccessful response",
          level: :error,
          tags: {integration: "woo", concern: "Gettable"},
          extra: {
            url: order_url,
            query: {},
            status_code: 401,
            error_code: nil,
            error_message: "Unauthorized",
            error_data: nil,
            body_preview: '{"message":"Unauthorized"}'
          }
        )
      end
    end

    context "when the response is not JSON" do
      before do
        allow(HTTParty).to receive(:get).and_return(instance_double(HTTParty::Response, body: "<html>", code: 200, success?: true))
      end

      it "returns nil and reports the invalid body" do
        expect(client.fetch_order(1)).to be_nil
        expect(Sentry).to have_received(:capture_message).with(
          "Woo API GET returned invalid JSON",
          hash_including(level: :error, tags: {integration: "woo", concern: "Gettable"})
        )
      end
    end
  end
end
