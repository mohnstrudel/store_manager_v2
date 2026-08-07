# frozen_string_literal: true

require "rails_helper"

RSpec.describe Seal::Api::Client do
  let(:client) { described_class.new }

  describe "#find_subscription_for_order" do
    let(:subscription) do
      {
        "order_id" => "111",
        "items" => [{"product_id" => "gid://shopify/Product/1"}],
        "billing_attempts" => [
          {"order_id" => "222"},
          {"order_id" => "333"}
        ]
      }
    end

    let(:page_one_response) do
      instance_double(HTTParty::Response, success?: true, body: {"payload" => {"subscriptions" => [subscription], "page" => 1, "total_pages" => 2}}.to_json)
    end

    let(:page_two_response) do
      instance_double(HTTParty::Response, success?: true, body: {"payload" => {"subscriptions" => [], "page" => 2, "total_pages" => 2}}.to_json)
    end

    before do
      allow(HTTParty).to receive(:get).and_return(page_one_response, page_two_response)
    end

    it "finds a subscription by its origin order id" do
      result = client.find_subscription_for_order("gid://shopify/Order/111")

      expect(result).to eq(subscription)
    end

    it "finds a subscription by one of its billing attempt order ids" do
      result = client.find_subscription_for_order("gid://shopify/Order/333")

      expect(result).to eq(subscription)
    end

    it "returns nil when no subscription matches" do
      result = client.find_subscription_for_order("gid://shopify/Order/999")

      expect(result).to be_nil
    end

    it "returns nil when the order id is blank" do
      expect(client.find_subscription_for_order(nil)).to be_nil
      expect(client.find_subscription_for_order("")).to be_nil
    end

    it "authenticates with the X-Seal-Token header" do
      client.find_subscription_for_order("gid://shopify/Order/111")

      expect(HTTParty).to have_received(:get).with(
        "#{described_class::BASE_URL}subscriptions",
        query: hash_including(page: 1),
        headers: {"X-Seal-Token" => described_class::TOKEN}
      )
    end

    it "only builds the index once across multiple lookups on the same instance" do
      client.find_subscription_for_order("gid://shopify/Order/111")
      client.find_subscription_for_order("gid://shopify/Order/222")

      expect(HTTParty).to have_received(:get).once
    end

    context "when the API returns an unsuccessful response" do
      let(:page_one_response) { instance_double(HTTParty::Response, success?: false, code: 401, body: "") }

      it "raises ApiError" do
        expect {
          client.find_subscription_for_order("gid://shopify/Order/111")
        }.to raise_error(described_class::ApiError, /HTTP 401/)
      end
    end
  end

  describe "::shared" do
    it "memoizes a single instance" do
      expect(described_class.shared).to be(described_class.shared)
    end
  end

  describe "#each_subscription_detail" do
    it "fetches full subscription records from the detail endpoint" do
      list_response = instance_double(
        HTTParty::Response,
        success?: true,
        body: {"payload" => {"subscriptions" => [{"id" => 10}]}}.to_json
      )
      detail_response = instance_double(
        HTTParty::Response,
        success?: true,
        body: {"payload" => {"id" => 10, "billing_max_cycles" => 4}}.to_json
      )
      allow(HTTParty).to receive(:get).and_return(list_response, detail_response)

      expect { |block|
        client.each_subscription_detail(&block)
      }.to yield_with_args(hash_including("id" => 10, "billing_max_cycles" => 4))

      expect(HTTParty).to have_received(:get).with(
        "#{described_class::BASE_URL}subscription",
        query: {id: 10},
        headers: {"X-Seal-Token" => described_class::TOKEN}
      )
    end
  end

  describe "#selling_plans_by_id" do
    it "indexes subscription-rule selling plans by their Shopify ID" do
      response = instance_double(
        HTTParty::Response,
        success?: true,
        body: {
          "payload" => {
            "subscription_rules" => [
              {"selling_plans" => [{"selling_plan_id" => "plan-1", "billing_max_cycles" => 4}]}
            ],
            "page" => 1,
            "total_pages" => 1
          }
        }.to_json
      )
      allow(HTTParty).to receive(:get).and_return(response)

      expect(client.selling_plans_by_id).to eq(
        "plan-1" => {"selling_plan_id" => "plan-1", "billing_max_cycles" => 4}
      )
    end
  end
end
