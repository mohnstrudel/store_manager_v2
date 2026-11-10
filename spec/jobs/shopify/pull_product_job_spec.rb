# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::PullProductJob do
  include ActiveJob::TestHelper

  let(:job) { described_class.new }
  let(:product_id) { "gid://shopify/Product/12345" }
  let(:api_response) do
    {
      "id" => product_id,
      "title" => "Elden Ring - Malenia | 1:4 | Resin Statue | by Prime 1 Studio",
      "handle" => "test-product",
      "createdAt" => "2024-01-01T00:00:00Z",
      "updatedAt" => "2024-01-01T00:00:00Z",
      "variants" => {
        "edges" => [
          {
            "node" => {
              "id" => "gid://shopify/ProductVariant/1",
              "title" => "Regular",
              "sku" => "TEST-SKU-001",
              "selectedOptions" => []
            }
          }
        ]
      },
      "media" => {
        "nodes" => [
          {
            "id" => "gid://shopify/MediaImage/1",
            "alt" => "Test Image",
            "image" => {"url" => "https://example.com/image.jpg"},
            "createdAt" => "2024-01-01T00:00:00Z",
            "updatedAt" => "2024-01-01T00:00:00Z"
          }
        ]
      }
    }
  end

  describe ".queue_as" do
    it "enqueues on the default queue" do
      expect {
        described_class.perform_later(product_id)
      }.to have_enqueued_job(described_class).on_queue("default")
    end
  end

  describe ".perform_later" do
    it "enqueues the job with product_id" do
      expect {
        described_class.perform_later(product_id)
      }.to have_enqueued_job(described_class).with(product_id)
    end
  end

  describe "#perform" do
    let(:api_client) { instance_double(Shopify::Api::Client) }
    let(:parsed_product) do
      {
        title: "Simple Figure",
        store_id: "gid://shopify/Product/12345"
      }
    end
    let(:imported_product) { instance_double(Product) }

    before do
      allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
      allow(api_client).to receive(:fetch_product).with(product_id).and_return(api_response)
      allow(Product::Shopify::Parser).to receive(:parse).with(api_response).and_return(parsed_product)
      allow(Product::Shopify::Importer).to receive(:import).with(parsed_product, force: true).and_return(imported_product)
    end

    context "with valid product_id and valid response" do
      it "creates API client" do
        job.perform(product_id)
        expect(Shopify::Api::Client).to have_received(:new)
      end

      it "pulls product from Shopify" do
        job.perform(product_id)
        expect(api_client).to have_received(:fetch_product).with(product_id)
      end

      it "parses and imports the response" do
        job.perform(product_id)
        expect(Product::Shopify::Parser).to have_received(:parse).with(api_response)
        expect(Product::Shopify::Importer).to have_received(:import).with(parsed_product, force: true)
      end

      it "creates or updates product" do
        job.perform(product_id)
        expect(Product::Shopify::Importer).to have_received(:import).with(parsed_product, force: true)
      end
    end

    context "when API client fails" do
      let(:http_response) do
        ShopifyAPI::Clients::HttpResponse.new(
          code: 500,
          headers: {},
          body: "Internal server error"
        )
      end
      let(:api_error) do
        ShopifyAPI::Errors::HttpResponseError.new(
          response: http_response
        )
      end

      before do
        allow(api_client).to receive(:fetch_product).and_raise(api_error)
      end

      it "propagates the error" do
        expect {
          job.perform(product_id)
        }.to raise_error(ShopifyAPI::Errors::HttpResponseError)
      end
    end

    context "when importer fails" do
      before do
        allow(Product::Shopify::Importer).to receive(:import).and_raise(
          ActiveRecord::RecordInvalid.new(Product.new)
        )
      end

      it "propagates the error" do
        expect {
          job.perform(product_id)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context "when response is blank" do
      let(:product) { create(:product) }

      before do
        allow(api_client).to receive(:fetch_product).with(product_id).and_return(nil)
      end

      it "returns early without calling parser or importer" do # rubocop:todo RSpec/MultipleExpectations
        job.perform(product_id)
        expect(Product::Shopify::Parser).not_to have_received(:parse)
        expect(Product::Shopify::Importer).not_to have_received(:import)
      end

      it "forgets the Shopify listing" do
        allow(Product).to receive(:forget_shopify_listing)

        job.perform(product_id)

        expect(Product).to have_received(:forget_shopify_listing).with(product_id)
      end
    end
  end

  describe "telling the requester" do
    let(:user) { create(:user) }
    let(:api_client) { instance_double(Shopify::Api::Client) }
    let(:jobs_link) { {label: "Open the jobs dashboard", href: "/jobs/statuses"} }
    let(:failure_alert) { {kind: "alert", message: "This product could not be pulled from Shopify.", link: jobs_link} }

    before do
      allow(Shopify::Api::Client).to receive(:new).and_return(api_client)
      allow(Product).to receive(:forget_shopify_listing)
      allow(api_client).to receive(:fetch_product).with(product_id).and_return(nil)
    end

    it "tells the requester the pull finished" do
      expect { described_class.perform_now(product_id, requested_by: user) }
        .to have_broadcasted_to(user).from_channel(NotificationsChannel)
        .with(kind: "success", message: "Shopify product pull finished.")
    end

    it "tells nobody when nobody asked" do
      expect { described_class.perform_now(product_id) }.not_to have_broadcasted_to(user).from_channel(NotificationsChannel)
    end

    it "alerts once and raises when the import fails" do
      allow(api_client).to receive(:fetch_product).with(product_id).and_return(api_response)
      allow(Product::Shopify::Importer).to receive(:import).and_raise(ActiveRecord::RecordInvalid.new(Product.new))

      expect { expect { described_class.perform_now(product_id, requested_by: user) }.to raise_error(ActiveRecord::RecordInvalid) }
        .to have_broadcasted_to(user).from_channel(NotificationsChannel).exactly(:once).with(failure_alert)
    end

    it "alerts once, when Shopify keeps throttling until the job gives up" do
      allow(api_client).to receive(:fetch_product).and_raise(Shopify::Api::Client::Throttled)

      freeze_time do
        described_class.perform_now(product_id, requested_by: user)
        8.times { ActiveJob::Base.execute(enqueued_jobs.last) }

        expect { expect { ActiveJob::Base.execute(enqueued_jobs.last) }.to raise_error(Shopify::Api::Client::Throttled) }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel).exactly(:once).with(failure_alert)
      end
    end

    it "is not retried by Sidekiq after the requester was told it failed" do
      expect(described_class.get_sidekiq_options).to include("retry" => false)
    end
  end
end
