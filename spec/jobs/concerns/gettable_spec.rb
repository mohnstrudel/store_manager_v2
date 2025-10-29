require "rails_helper"

RSpec.describe Gettable do
  let(:test_class) do
    Class.new do
      include Gettable
    end
  end

  let(:instance) { test_class.new }

  describe "Constants" do
    it "defines CONSUMER_KEY constant" do
      expect(Gettable::CONSUMER_KEY).to eq(Rails.application.credentials.dig(:woo_api, :user))
    end

    it "defines CONSUMER_SECRET constant" do
      expect(Gettable::CONSUMER_SECRET).to eq(Rails.application.credentials.dig(:woo_api, :pass))
    end

    it "defines PER_PAGE constant" do
      expect(Gettable::PER_PAGE).to eq(100)
    end
  end

  describe "#api_get_all" do
    let(:base_url) { "https://example.com/api/orders" }
    let(:total_records) { 250 }
    let(:expected_pages) { 3 }

    context "with valid parameters" do
      before do
        allow(instance).to receive(:api_get).and_return([{id: 1}, {id: 2}])
      end

      it "calculates correct number of pages" do
        result = instance.api_get_all(base_url, total_records)
        expect(instance).to have_received(:api_get).exactly(expected_pages).times
      end

      it "passes correct page numbers to api_get" do
        instance.api_get_all(base_url, total_records)

        expect(instance).to have_received(:api_get).with(base_url, nil, 100, 1)
        expect(instance).to have_received(:api_get).with(base_url, nil, 100, 2)
        expect(instance).to have_received(:api_get).with(base_url, nil, 100, 3)
      end

      it "flattens and compacts results" do
        allow(instance).to receive(:api_get).and_return(
          [{id: 1}],
          [{id: 2}, {id: 3}],
          []
        )

        result = instance.api_get_all(base_url, total_records)
        expect(result).to eq([{id: 1}, {id: 2}, {id: 3}])
      end
    end

    context "with custom pages parameter" do
      before do
        allow(instance).to receive(:api_get).and_return([{id: 1}])
      end

      it "uses provided pages instead of calculating" do
        custom_pages = 2
        instance.api_get_all(base_url, total_records, custom_pages)

        expect(instance).to have_received(:api_get).exactly(custom_pages).times
      end
    end

    context "with small total_records" do
      before do
        allow(instance).to receive(:api_get).and_return([{id: 1}])
      end

      it "uses 1 page when total_records < PER_PAGE" do
        small_total = 50
        instance.api_get_all(base_url, small_total)

        expect(instance).to have_received(:api_get).once
      end
    end
  end

  describe "#api_get_order" do
    let(:order_id) { "12345" }
    let(:order_url) { "https://store.handsomecake.com/wp-json/wc/v3/orders/#{order_id}" }

    before do
      allow(instance).to receive(:api_get).and_return({id: order_id, status: "processing"})
    end

    it "calls api_get with correct order URL" do
      instance.api_get_order(order_id)
      expect(instance).to have_received(:api_get).with(order_url)
    end

    it "returns the order data" do
      result = instance.api_get_order(order_id)
      expect(result).to eq({id: order_id, status: "processing"})
    end
  end

  describe "#api_get_latest_orders" do
    let(:orders_url) { "https://store.handsomecake.com/wp-json/wc/v3/orders/" }

    before do
      allow(instance).to receive(:api_get).and_return([{id: 1}, {id: 2}])
    end

    it "calls api_get with orders endpoint and PER_PAGE" do
      instance.api_get_latest_orders
      expect(instance).to have_received(:api_get).with(orders_url, nil, Gettable::PER_PAGE, 1)
    end

    it "returns the latest orders" do
      result = instance.api_get_latest_orders
      expect(result).to eq([{id: 1}, {id: 2}])
    end
  end

  describe "#api_get" do
    let(:test_url) { "https://example.com/api/test" }
    let(:mock_response) { double("Response", body: '{"id": 1, "name": "Test"}') }

    context "with successful HTTP request" do
      before do
        allow(HTTParty).to receive(:get).and_return(mock_response)
      end

      it "makes HTTP GET request with basic auth" do
        instance.api_get(test_url)

        expect(HTTParty).to have_received(:get).with(
          test_url,
          query: {},
          basic_auth: {
            username: Gettable::CONSUMER_KEY,
            password: Gettable::CONSUMER_SECRET
          }
        )
      end

      it "passes query parameters when provided" do
        params = {status: "processing", per_page: 50, page: 2, order: "desc"}
        instance.api_get(test_url, *params.values)

        expect(HTTParty).to have_received(:get).with(
          test_url,
          query: params.compact,
          basic_auth: {
            username: Gettable::CONSUMER_KEY,
            password: Gettable::CONSUMER_SECRET
          }
        )
      end

      it "parses JSON response with symbolized keys" do
        result = instance.api_get(test_url)
        expect(result).to eq({id: 1, name: "Test"})
      end

      it "handles nil parameters gracefully" do
        instance.api_get(test_url, nil, nil, nil, nil)

        expect(HTTParty).to have_received(:get).with(
          test_url,
          query: {},
          basic_auth: {
            username: Gettable::CONSUMER_KEY,
            password: Gettable::CONSUMER_SECRET
          }
        )
      end
    end

    context "when HTTP request raises an exception" do
      let(:error_message) { "Network error" }

      before do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new(error_message))
        allow(Rails.logger).to receive(:error)
        allow(instance).to receive(:sleep) # Mock sleep to avoid actual delays
      end

      it "retries up to 3 times" do
        instance.api_get(test_url)
        expect(HTTParty).to have_received(:get).exactly(3).times
      end

      it "logs the error after final retry" do
        instance.api_get(test_url)
        expect(Rails.logger).to have_received(:error).with("Gettable. Error: #{error_message}")
      end

      it "returns nil after all retries fail" do
        result = instance.api_get(test_url)
        expect(result).to be_nil
      end
    end

    context "when HTTP request succeeds on retry" do
      before do
        call_count = 0
        allow(HTTParty).to receive(:get) do
          call_count += 1
          case call_count
          when 1, 2
            raise StandardError.new("Failure #{call_count}")
          else
            mock_response
          end
        end
        allow(instance).to receive(:sleep) # Mock sleep to avoid actual delays
      end

      it "retries until successful" do
        result = instance.api_get(test_url)
        expect(HTTParty).to have_received(:get).exactly(3).times
        expect(result).to eq({id: 1, name: "Test"})
      end
    end
  end
end
