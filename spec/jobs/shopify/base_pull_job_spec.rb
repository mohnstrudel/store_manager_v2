# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::BasePullJob do
  include ActiveJob::TestHelper

  let(:pull_class) { class_double(Shopify::Pull) }
  let(:page) { Shopify::Pull::Page.new(imported_count: 2, next_cursor: nil, failures: []) }
  let(:job_class) do
    pull_class = self.pull_class

    Class.new(described_class) do
      def self.name
        "TestJob"
      end

      define_method(:pull_class) { pull_class }

      def handle_terminal_page
        @terminal_page_handled = true
      end

      def terminal_page_handled?
        @terminal_page_handled || false
      end
    end
  end
  let(:job) { job_class.new }
  let(:job_setter) { instance_double(ActiveJob::ConfiguredJob, perform_later: true) }

  before do
    allow(pull_class).to receive(:page).and_return(page)
    allow(job_class).to receive(:set).and_return(job_setter)
  end

  it "enqueues on the default queue" do
    expect { job_class.perform_later }.to have_enqueued_job(job_class).on_queue("default")
  end

  describe "#perform" do
    it "pulls the page for the given cursor and limit" do
      job.perform(cursor: "abc", limit: 5)

      expect(pull_class).to have_received(:page).with(cursor: "abc", limit: 5)
    end

    it "invokes the terminal-page hook when there is no next page" do
      job.perform

      expect(job_class).not_to have_received(:set)
      expect(job.terminal_page_handled?).to be(true)
    end

    context "when Shopify reports another page" do
      let(:page) { Shopify::Pull::Page.new(imported_count: 2, next_cursor: "next", failures: []) }

      it "schedules the next page without invoking the terminal-page hook" do
        job.perform

        expect(job_class).to have_received(:set).with(wait: 1.second)
        expect(job_setter).to have_received(:perform_later).with(cursor: "next")
        expect(job.terminal_page_handled?).to be(false)
      end

      it "treats a limited pull as terminal" do
        job.perform(limit: 5)

        expect(job_class).not_to have_received(:set)
        expect(job.terminal_page_handled?).to be(true)
      end
    end

    context "when items on the page failed to import" do
      let(:failures) { [Shopify::Pull::Failure.new(store_id: "gid://1", message: "boom", failed_at: Time.current)] }
      let(:page) { Shopify::Pull::Page.new(imported_count: 1, next_cursor: "next", failures:) }

      before { allow(Sentry).to receive(:capture_exception) }

      it "schedules the next page before raising the failures" do
        expect { job.perform }.to raise_error(Shopify::Pull::Failed) { |error| expect(error.failures).to eq(failures) }

        expect(job_setter).to have_received(:perform_later).with(cursor: "next")
      end

      it "reports the failures and discards the job instead of retrying the page" do
        job_class.perform_now

        expect(Sentry).to have_received(:capture_exception).with(an_instance_of(Shopify::Pull::Failed))
        expect(job_setter).to have_received(:perform_later).once
      end

      it "writes no import failure" do
        expect { job_class.perform_now }.not_to change(Sale::ImportFailure, :count)
      end
    end

    context "when Shopify responds with an HTTP error" do
      def http_error(code)
        ShopifyAPI::Errors::HttpResponseError.new(
          response: ShopifyAPI::Clients::HttpResponse.new(code:, headers: {}, body: "error")
        )
      end

      it "re-enqueues a rate-limited page with linear backoff" do
        allow(pull_class).to receive(:page).and_raise(http_error(429))

        job.perform(attempts: 2, cursor: "abc")

        expect(job_class).to have_received(:set).with(wait: 15.seconds)
        expect(job_setter).to have_received(:perform_later).with(attempts: 3, cursor: "abc", limit: nil)
        expect(job.terminal_page_handled?).to be(false)
      end

      it "raises other Shopify API errors" do
        allow(pull_class).to receive(:page).and_raise(http_error(500))

        expect { job.perform }.to raise_error(ShopifyAPI::Errors::HttpResponseError)
      end
    end
  end
end
