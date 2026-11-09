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

  before do
    allow(pull_class).to receive(:page).and_return(page)
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
      expect { job.perform }.not_to have_enqueued_job(job_class)

      expect(job.terminal_page_handled?).to be(true)
    end

    context "when Shopify reports another page" do
      let(:page) { Shopify::Pull::Page.new(imported_count: 2, next_cursor: "next", failures: []) }

      it "schedules the next page with no wait and without invoking the terminal-page hook" do
        expect { job.perform }.to have_enqueued_job(job_class).with(cursor: "next").at(:no_wait)

        expect(job.terminal_page_handled?).to be(false)
      end

      it "treats a limited pull as terminal" do
        expect { job.perform(limit: 5) }.not_to have_enqueued_job(job_class)

        expect(job.terminal_page_handled?).to be(true)
      end
    end

    context "when items on the page failed to import" do
      let(:failures) { [Shopify::Pull::Failure.new(store_id: "gid://1", message: "boom", failed_at: Time.current)] }
      let(:page) { Shopify::Pull::Page.new(imported_count: 1, next_cursor: "next", failures:) }

      before { allow(Sentry).to receive(:capture_exception) }

      it "schedules the next page before raising the failures" do
        expect { job.perform }.to raise_error(Shopify::Pull::Failed) { |error| expect(error.failures).to eq(failures) }

        expect(job_class).to have_been_enqueued.with(cursor: "next")
      end

      it "reports the failures and discards the job instead of retrying the page" do
        job_class.perform_now

        expect(Sentry).to have_received(:capture_exception).with(an_instance_of(Shopify::Pull::Failed))
        expect(job_class).to have_been_enqueued.once
      end

      it "writes no import failure" do
        expect { job_class.perform_now }.not_to change(Sale::ImportFailure, :count)
      end
    end

    context "when Shopify throttles the page" do
      let(:job) { job_class.new(cursor: "abc", limit: 5) }

      before { allow(pull_class).to receive(:page).and_raise(Shopify::Api::Client::Throttled) }

      it "re-enqueues the same page with its cursor and limit" do
        expect { job.perform_now }.to have_enqueued_job(job_class).with(cursor: "abc", limit: 5)
      end

      it "does not invoke the terminal-page hook" do
        job.perform_now

        expect(job.terminal_page_handled?).to be(false)
      end
    end
  end
end
