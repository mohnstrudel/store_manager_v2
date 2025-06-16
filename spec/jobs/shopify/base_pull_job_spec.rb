require "rails_helper"

RSpec.describe Shopify::BasePullJob do
  let(:job_class) do
    Class.new(described_class) do
      def self.name
        "TestJob"
      end

      def resource_name
        "test"
      end

      def batch_size
        10
      end

      def parser_class
        @parser_class ||= Class.new do
          def initialize(item)
            @item = item
          end

          def parse
            {}
          end
        end
      end

      def creator_class
        @creator_class ||= Class.new do
          def initialize(item)
            @item = item
          end

          def update_or_create!
            true
          end
        end
      end
    end
  end

  let(:job) { job_class.new }
  let(:api_client) { instance_double(Shopify::ApiClient) }
  let(:api_response) do
    {
      items: [
        {"id" => "1"},
        {"id" => "2"}
      ],
      has_next_page: false,
      end_cursor: "end_cursor_value"
    }
  end

  let(:parser) { instance_double("Parser", parse: {}) }
  let(:creator) { instance_double("Creator", update_or_create!: true) }
  let(:parser_class) { class_double("ParserClass", new: parser) }
  let(:creator_class) { class_double("CreatorClass", new: creator) }
  let(:job_setter) { instance_double("JobSetter", perform_later: true) }

  before do
    allow(Shopify::ApiClient).to receive(:new).and_return(api_client)
    allow(api_client).to receive(:pull).and_return(api_response)

    allow(job).to receive(:parser_class).and_return(parser_class)
    allow(job).to receive(:creator_class).and_return(creator_class)
    allow(job_class).to receive(:set).and_return(job_setter)
  end

  describe "#perform" do
    subject(:perform_job) { job.perform(**job_params) }
    let(:job_params) { {} }

    it "uses the configured batch size" do
      perform_job
      expect(api_client).to have_received(:pull).with(
        resource_name: "test",
        cursor: nil,
        batch_size: 10
      )
    end

    it "processes each item through parser and creator" do
      perform_job
      expect(parser_class).to have_received(:new).exactly(2).times
      expect(creator_class).to have_received(:new).exactly(2).times
    end

    context "when processing with a limit" do
      let(:job_params) { {limit: 5} }

      it "uses the provided limit" do
        perform_job
        expect(api_client).to have_received(:pull).with(
          resource_name: "test",
          cursor: nil,
          batch_size: 5
        )
      end

      it "does not schedule another job even with more pages" do
        modified_api_response = api_response.dup
        modified_api_response[:has_next_page] = true
        allow(api_client).to receive(:pull).and_return(modified_api_response)

        perform_job
        expect(job_class).not_to have_received(:set)
      end
    end

    context "when handling rate limits" do
      let(:job_params) { {attempts: 2} }
      let(:http_response) do
        ShopifyAPI::Clients::HttpResponse.new(
          code: 429,
          headers: {},
          body: "Rate limit exceeded"
        )
      end
      let(:rate_limit_error) do
        ShopifyAPI::Errors::HttpResponseError.new(
          response: http_response
        )
      end

      before do
        allow(api_client).to receive(:pull).and_raise(rate_limit_error)
      end

      it "retries with exponential backoff" do
        perform_job
        expect(job_class).to have_received(:set).with(wait: 15.seconds)
        expect(job_setter).to have_received(:perform_later).with(attempts: 3, cursor: nil, limit: nil)
      end

      it "raises other Shopify API errors" do
        other_response = ShopifyAPI::Clients::HttpResponse.new(
          code: 500,
          headers: {},
          body: "Internal server error"
        )
        other_error = ShopifyAPI::Errors::HttpResponseError.new(
          response: other_response
        )
        allow(api_client).to receive(:pull).and_raise(other_error)

        expect { perform_job }.to raise_error(ShopifyAPI::Errors::HttpResponseError)
      end
    end

    context "when handling pagination" do
      let(:modified_api_response) do
        api_response.dup.tap do |data|
          data[:has_next_page] = true
        end
      end

      before do
        allow(api_client).to receive(:pull).and_return(modified_api_response)
      end

      it "schedules next job when there are more pages" do
        perform_job
        expect(job_class).to have_received(:set).with(wait: 1.second)
        expect(job_setter).to have_received(:perform_later)
          .with(cursor: modified_api_response[:end_cursor])
      end

      it "does not schedule next job when there are no more pages" do
        allow(api_client).to receive(:pull).and_return(api_response)
        perform_job
        expect(job_class).not_to have_received(:set)
      end
    end
  end

  describe "required methods" do
    let(:base_job) { described_class.new }

    it "raises NotImplementedError for resource_name" do
      expect { base_job.send(:resource_name) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for parser_class" do
      expect { base_job.send(:parser_class) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for creator_class" do
      expect { base_job.send(:creator_class) }.to raise_error(NotImplementedError)
    end

    it "raises NotImplementedError for batch_size" do
      expect { base_job.send(:batch_size) }.to raise_error(NotImplementedError)
    end
  end
end
