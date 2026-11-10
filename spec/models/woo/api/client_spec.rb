# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::Api::Client do
  let(:client) { described_class.new }
  let(:basic_auth) { {username: described_class::CONSUMER_KEY, password: described_class::CONSUMER_SECRET} }
  let(:request_options) { {basic_auth:, open_timeout: 5, read_timeout: 20} }
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
          **request_options
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

    it "flattens the pages" do
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
        **request_options
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
        **request_options
      )
    end
  end

  describe "#update_order_status" do
    it "posts the status with the API credentials and the same timeouts as a read" do
      allow(HTTParty).to receive(:post)

      client.update_order_status("4321", "completed")

      expect(HTTParty).to have_received(:post).with(
        "#{described_class::ORDERS_URL}4321",
        body: {status: "completed"},
        **request_options
      )
    end
  end

  describe "timeouts" do
    it "gives the connection 5 seconds and each read 20, so a stalled store cannot hold a pull for a minute per page" do
      connections = []
      allow(Net::HTTP).to receive(:new).and_wrap_original { |original, *args| original.call(*args).tap { |http| connections << http } }
      stub_request(:get, "#{described_class::ORDERS_URL}1").to_return(status: 200, body: '{"id": 1}')

      client.fetch_order(1)

      expect(connections).to contain_exactly(have_attributes(open_timeout: 5, read_timeout: 20))
    end
  end

  describe "GET failures", :aggregate_failures do
    let(:order_url) { "#{described_class::ORDERS_URL}1" }

    def raised_by_fetch_order
      client.fetch_order(1)
    rescue described_class::Error => error
      error
    end

    it "organizes the errors by what the caller can do about them" do
      expect(described_class::Unavailable).to be < described_class::Error
      expect(described_class::NotFound).to be < described_class::Error
      expect(described_class::NotFound).not_to be < described_class::Unavailable
    end

    [Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError].each do |network_error|
      it "raises Unavailable without retrying on #{network_error}" do
        stub_request(:get, order_url).to_raise(network_error)

        expect(raised_by_fetch_order).to be_a(described_class::Unavailable).and have_attributes(url: order_url, status: nil)
        expect(a_request(:get, order_url)).to have_been_made.once
      end
    end

    [429, 500, 502, 503].each do |status|
      it "raises Unavailable on HTTP #{status}" do
        stub_request(:get, order_url).to_return(status:, body: "<html>busy</html>")

        expect(raised_by_fetch_order).to be_a(described_class::Unavailable).and have_attributes(status:, url: order_url, body_preview: "<html>busy</html>")
        expect(a_request(:get, order_url)).to have_been_made.once
      end
    end

    it "raises NotFound on HTTP 404" do
      stub_request(:get, order_url).to_return(status: 404, body: '{"code":"woocommerce_rest_shop_order_invalid_id","message":"Invalid ID."}')

      expect(raised_by_fetch_order).to be_a(described_class::NotFound).and have_attributes(status: 404, url: order_url)
    end

    it "raises Error with the Woo message on a rejected request" do
      stub_request(:get, order_url).to_return(status: 401, body: '{"message":"Unauthorized"}')

      error = raised_by_fetch_order

      expect(error).to be_instance_of(described_class::Error)
      expect(error).to have_attributes(status: 401, url: order_url, body_preview: '{"message":"Unauthorized"}')
      expect(error.message).to include("HTTP 401", "Unauthorized", order_url)
    end

    it "raises Error when the response body is blank" do
      stub_request(:get, order_url).to_return(status: 200, body: "")

      expect(raised_by_fetch_order).to be_instance_of(described_class::Error)
    end

    it "raises Error when the response is not JSON" do
      stub_request(:get, order_url).to_return(status: 200, body: "<html>")

      expect(raised_by_fetch_order).to be_instance_of(described_class::Error)
    end

    it "does not reach Sentry itself" do
      allow(Sentry).to receive(:capture_message)
      stub_request(:get, order_url).to_return(status: 500)

      raised_by_fetch_order

      expect(Sentry).not_to have_received(:capture_message)
    end

    it "raises instead of dropping a page that fails in the middle of a list" do
      list_url = described_class::ORDERS_URL
      stub_request(:get, list_url).with(query: hash_including("page" => "1")).to_return(status: 200, body: '[{"id": 1}]')
      stub_request(:get, list_url).with(query: hash_including("page" => "2")).to_return(status: 502)

      expect { client.fetch_orders(150) }.to raise_error(described_class::Unavailable) { |error| expect(error.status).to eq(502) }
    end
  end
end
