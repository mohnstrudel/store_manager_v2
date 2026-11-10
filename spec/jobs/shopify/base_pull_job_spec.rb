# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::BasePullJob do
  include ActiveJob::TestHelper

  let(:pull_class) { class_double(Shopify::Pull) }
  let(:page) { Shopify::Pull::Page.new(imported_count: 2, next_cursor: nil, failures: []) }
  let(:last_sync_at) { nil }
  let(:stamped_syncs) { [] }
  let(:terminal_pages) { [] }
  let(:job_class) do
    pull_class = self.pull_class
    last_sync_at = self.last_sync_at
    stamped_syncs = self.stamped_syncs
    terminal_pages = self.terminal_pages

    Class.new(described_class) do
      def self.name
        "TestJob"
      end

      define_method(:pull_class) { pull_class }
      define_method(:last_sync_at) { last_sync_at }
      define_method(:stamp_sync) { |started_at| stamped_syncs << started_at }
      define_method(:handle_terminal_page) { |updated_since:| terminal_pages << updated_since }
      define_method(:job_title) { "Test pull" }
      define_method(:failure_notification) { |_error| {message: "Some test records could not be pulled."} }
    end
  end
  let(:job) { job_class.new }
  let(:started_at) { Time.utc(2026, 11, 10, 12, 0, 0) }
  let(:updated_since) { Time.utc(2026, 11, 10, 9, 45, 0) }

  before do
    allow(pull_class).to receive(:page).and_return(page)
  end

  it "enqueues on the default queue" do
    expect { job_class.perform_later }.to have_enqueued_job(job_class).on_queue("default")
  end

  describe "#perform" do
    context "when the pull is a full pull" do
      let(:last_sync_at) { Time.utc(2026, 11, 10, 10, 0, 0) }

      it "pulls the first page unfiltered even when a sync time is stored" do
        job.perform

        expect(pull_class).to have_received(:page).with(cursor: nil, updated_since: nil)
      end

      it "stores the start of the pull and hands the terminal page its filter when there is no next page" do
        travel_to(started_at) { job.perform }

        expect(stamped_syncs).to eq([started_at])
        expect(terminal_pages).to eq([nil])
      end

      it "schedules the next page carrying the start time and no filter, and stores nothing yet" do
        allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 2, next_cursor: "next", failures: []))

        expect { travel_to(started_at) { job.perform } }
          .to have_enqueued_job(job_class).with(cursor: "next", started_at:, updated_since: nil).at(:no_wait)

        expect(stamped_syncs).to be_empty
        expect(terminal_pages).to be_empty
      end
    end

    context "when the pull is a changes pull" do
      let(:last_sync_at) { Time.utc(2026, 11, 10, 10, 0, 0) }

      it "pulls the first page filtered from the stored sync time minus 15 minutes" do
        travel_to(started_at) { job.perform(changes_only: true) }

        expect(pull_class).to have_received(:page).with(cursor: nil, updated_since:)
      end

      it "schedules the next page carrying the start time and the filter, and stores nothing yet" do
        allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 2, next_cursor: "next", failures: []))

        expect { travel_to(started_at) { job.perform(changes_only: true) } }
          .to have_enqueued_job(job_class).with(cursor: "next", started_at:, updated_since:).at(:no_wait)

        expect(stamped_syncs).to be_empty
      end

      context "when the stored sync time moved after the first page" do
        let(:last_sync_at) { Time.utc(2026, 11, 10, 11, 0, 0) }

        it "pulls a later page with the carried filter" do
          job.perform(cursor: "next", started_at:, updated_since:)

          expect(pull_class).to have_received(:page).with(cursor: "next", updated_since:)
        end
      end

      it "stores the carried start time rather than the time of the terminal page, then hands over the filter" do
        travel_to(Time.utc(2026, 11, 10, 12, 3, 0)) { job.perform(cursor: "last", started_at:, updated_since:) }

        expect(stamped_syncs).to eq([started_at])
        expect(terminal_pages).to eq([updated_since])
      end

      context "when no sync time is stored" do
        let(:last_sync_at) { nil }

        it "runs a full pull" do
          expect { travel_to(started_at) { job.perform(changes_only: true) } }
            .not_to have_enqueued_job(job_class)

          expect(pull_class).to have_received(:page).with(cursor: nil, updated_since: nil)
          expect(terminal_pages).to eq([nil])
        end

        it "carries no filter to the next page" do
          allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 2, next_cursor: "next", failures: []))

          expect { travel_to(started_at) { job.perform(changes_only: true) } }
            .to have_enqueued_job(job_class).with(cursor: "next", started_at:, updated_since: nil)
        end
      end
    end

    context "when a pull spans several pages" do
      let(:last_sync_at) { Time.utc(2026, 11, 10, 10, 0, 0) }
      let(:pages) do
        [
          Shopify::Pull::Page.new(imported_count: 1, next_cursor: "cursor-1", failures: []),
          Shopify::Pull::Page.new(imported_count: 1, next_cursor: "cursor-2", failures: []),
          Shopify::Pull::Page.new(imported_count: 1, next_cursor: nil, failures: [])
        ]
      end

      before do
        stub_const("TestJob", job_class)
        allow(pull_class).to receive(:page).and_return(*pages)
      end

      def run_pages_at(*times)
        travel_to(times.first) { job_class.perform_now(changes_only: true) }
        times.drop(1).each { |time| travel_to(time) { ActiveJob::Base.execute(enqueued_jobs.last) } }
      end

      it "filters every page the same way and stores the first page's start time once, after the last page" do
        run_pages_at(started_at, started_at + 1.minute, started_at + 3.minutes)

        expect(pull_class).to have_received(:page).with(cursor: nil, updated_since:).once
        expect(pull_class).to have_received(:page).with(cursor: "cursor-1", updated_since:).once
        expect(pull_class).to have_received(:page).with(cursor: "cursor-2", updated_since:).once
        expect(stamped_syncs).to eq([started_at])
      end

      it "stores nothing when the chain stops before its last page" do
        run_pages_at(started_at, started_at + 1.minute)

        expect(stamped_syncs).to be_empty
      end
    end

    context "when a chain enqueued before deploy continues without a start time" do
      it "finishes the chain unfiltered without storing a start time" do
        job.perform(cursor: "abc")

        expect(pull_class).to have_received(:page).with(cursor: "abc", updated_since: nil)
        expect(terminal_pages).to eq([nil])
        expect(stamped_syncs).to be_empty
      end
    end

    context "when items on the page failed to import" do
      let(:failures) { [Shopify::Pull::Failure.new(store_id: "gid://1", message: "boom", failed_at: Time.current)] }
      let(:page) { Shopify::Pull::Page.new(imported_count: 1, next_cursor: "next", failures:) }

      before { allow(Sentry).to receive(:capture_exception) }

      it "schedules the next page before raising the failures" do
        expect { job.perform }.to raise_error(Shopify::Pull::Failed) { |error| expect(error.failures).to eq(failures) }

        expect(job_class).to have_been_enqueued.with(hash_including(cursor: "next"))
      end

      it "reports the failures and discards the job instead of retrying the page" do
        job_class.perform_now

        expect(Sentry).to have_received(:capture_exception).with(an_instance_of(Shopify::Pull::Failed))
        expect(job_class).to have_been_enqueued.once
      end

      it "writes no import failure" do
        expect { job_class.perform_now }.not_to change(Sale::ImportFailure, :count)
      end

      it "carries how many items failed so far to the next page, adding this page's" do
        expect { job_class.perform_now(cursor: "page-2", started_at:, updated_since: nil, failed_count: 2) }
          .to have_enqueued_job(job_class).with(cursor: "next", started_at:, updated_since: nil, failed_count: 3)
      end

      context "when it is the last page" do
        let(:page) { Shopify::Pull::Page.new(imported_count: 1, next_cursor: nil, failures:) }

        it "still stores the start time and runs the terminal-page hook before reporting" do
          travel_to(started_at) { job_class.perform_now }

          expect(stamped_syncs).to eq([started_at])
          expect(terminal_pages).to eq([nil])
          expect(Sentry).to have_received(:capture_exception).with(an_instance_of(Shopify::Pull::Failed))
        end
      end

      context "when the job holds the sync time back after failures" do
        let(:job_class) do
          Class.new(super()) do
            define_method(:stamp_past_failures?) { false }
          end
        end

        it "stores nothing after a last page that failed, but still runs the terminal-page hook" do
          allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 1, next_cursor: nil, failures:))

          travel_to(started_at) { job_class.perform_now }

          expect(stamped_syncs).to be_empty
          expect(terminal_pages).to eq([nil])
        end

        it "stores nothing after a clean last page when an earlier page failed" do
          allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 1, next_cursor: nil, failures: []))

          travel_to(started_at) { job_class.perform_now(cursor: "last", started_at:, updated_since: nil, failed_count: 1) }

          expect(stamped_syncs).to be_empty
          expect(terminal_pages).to eq([nil])
        end

        it "stores the start time when nothing failed" do
          allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 1, next_cursor: nil, failures: []))

          travel_to(started_at) { job_class.perform_now }

          expect(stamped_syncs).to eq([started_at])
        end
      end
    end

    context "when a requester is given" do
      let(:user) { create(:user) }

      it "carries the requester to the next page" do
        allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 2, next_cursor: "next", failures: []))

        expect { travel_to(started_at) { job.perform(requested_by: user) } }
          .to have_enqueued_job(job_class).with(cursor: "next", started_at:, updated_since: nil, requested_by: user)
      end

      it "tells the requester nothing while more pages remain" do
        allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 2, next_cursor: "next", failures: []))

        expect { job.perform(requested_by: user) }.not_to have_broadcasted_to(user).from_channel(NotificationsChannel)
      end

      it "tells the requester the pull finished after a clean last page" do
        expect { job_class.perform_now(requested_by: user) }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "notice", message: "Test pull finished.").exactly(:once)
      end

      it "tells the requester only about the failures after a last page with failures" do # rubocop:disable RSpec/ExampleLength
        failures = [Shopify::Pull::Failure.new(store_id: "gid://1", message: "boom", failed_at: Time.current)]
        allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 1, next_cursor: nil, failures:))
        allow(Sentry).to receive(:capture_exception)

        expect { job_class.perform_now(requested_by: user) }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel).exactly(:once)
          .and have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "Some test records could not be pulled.")
      end

      context "when items failed to import" do
        let(:failures) { [Shopify::Pull::Failure.new(store_id: "gid://1", message: "boom", failed_at: Time.current)] }

        before { allow(Sentry).to receive(:capture_exception) }

        it "tells the requester nothing about a failed page while more pages remain" do
          allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 1, next_cursor: "next", failures:))

          expect { job_class.perform_now(requested_by: user) }.not_to have_broadcasted_to(user).from_channel(NotificationsChannel)
        end

        it "tells the requester once, after the last page, when only an earlier page failed" do # rubocop:disable RSpec/ExampleLength
          expect { job_class.perform_now(cursor: "last", started_at:, updated_since: nil, failed_count: 2, requested_by: user) }
            .to have_broadcasted_to(user).from_channel(NotificationsChannel).exactly(:once)
            .and have_broadcasted_to(user).from_channel(NotificationsChannel)
            .with(kind: "alert", message: "Some test records could not be pulled.")
        end

        it "tells the requester once when the last page failed after an earlier page did" do
          allow(pull_class).to receive(:page).and_return(Shopify::Pull::Page.new(imported_count: 1, next_cursor: nil, failures:))

          expect { job_class.perform_now(cursor: "last", started_at:, updated_since: nil, failed_count: 4, requested_by: user) }
            .to have_broadcasted_to(user).from_channel(NotificationsChannel).exactly(:once)
        end

        it "hands the alert the number of items that failed across the pull" do
          errors = []
          job_class.define_method(:failure_notification) do |error|
            errors << error
            {message: "Some test records could not be pulled."}
          end

          job_class.perform_now(cursor: "last", started_at:, updated_since: nil, failed_count: 4, requested_by: user)

          expect(errors).to match([an_instance_of(Shopify::Pull::Failed).and(have_attributes(message: start_with("4 Shopify item(s)")))])
        end
      end

      it "tells the requester once when the pull stops on an unexpected error" do
        allow(pull_class).to receive(:page).and_raise("boom")

        expect { expect { job_class.perform_now(requested_by: user) }.to raise_error("boom") }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel).exactly(:once)
          .and have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "Some test records could not be pulled.")
      end

      it "is not retried by Sidekiq after the requester was told it failed" do
        expect(described_class.get_sidekiq_options).to include("retry" => false)
      end
    end

    context "when a page raises an error that is not an item failure" do
      it "stores nothing and schedules no further page" do
        allow(pull_class).to receive(:page).and_raise("boom")

        expect { job.perform(cursor: "abc", started_at:, updated_since:) }.to raise_error("boom")

        expect(stamped_syncs).to be_empty
        expect(job_class).not_to have_been_enqueued
      end
    end

    context "when Shopify throttles the page" do
      before { allow(pull_class).to receive(:page).and_raise(Shopify::Api::Client::Throttled) }

      it "re-enqueues the same continuation page with its cursor, start time, and filter" do
        throttled_page = job_class.new(cursor: "abc", started_at:, updated_since:)

        expect { throttled_page.perform_now }
          .to have_enqueued_job(job_class).with(cursor: "abc", started_at:, updated_since:)
      end

      it "re-enqueues the first page of a changes pull as requested so the retry computes its start again" do
        throttled_first_page = job_class.new(changes_only: true)

        expect { throttled_first_page.perform_now }.to have_enqueued_job(job_class).with(changes_only: true)
      end

      it "stores nothing and does not invoke the terminal-page hook" do
        job_class.new(cursor: "abc", started_at:, updated_since:).perform_now

        expect(stamped_syncs).to be_empty
        expect(terminal_pages).to be_empty
      end
    end
  end
end
