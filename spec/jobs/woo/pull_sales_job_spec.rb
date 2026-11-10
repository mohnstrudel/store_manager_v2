# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::PullSalesJob, :aggregate_failures do
  include ActiveJob::TestHelper

  before { allow(Sale::Woo::Pull).to receive(:run) }

  describe "#perform" do
    it "pulls the orders with the given arguments and returns nothing" do
      expect(described_class.new.perform(limit: 100, pages: 5, id: "123")).to be_nil

      expect(Sale::Woo::Pull).to have_received(:run).with(limit: 100, pages: 5, id: "123")
    end

    context "when orders fail to import" do
      let(:failed_at) { Time.zone.local(2026, 11, 9, 12) }
      let(:failures) do
        [
          Sale::Woo::Pull::Failure.new(woo_id: 123, message: "boom", failed_at:),
          Sale::Woo::Pull::Failure.new(woo_id: 456, message: "bang", failed_at:)
        ]
      end
      let(:sentry_event) { instance_double(Sentry::ErrorEvent, event_id: "event-1") }

      before do
        allow(Sale::Woo::Pull).to receive(:run).and_raise(Sale::Woo::Pull::Failed.new(failures))
        allow(Sentry).to receive(:capture_exception).and_return(sentry_event)
      end

      it "reports failed orders to Sentry and discards the job instead of retrying" do
        expect { described_class.perform_now }.not_to have_enqueued_job(described_class)

        expect(Sentry).to have_received(:capture_exception).with(
          an_instance_of(Sale::Woo::Pull::Failed),
          extra: {failed_woo_order_ids: [123, 456]}
        )
      end

      it "records each failed order with the Sentry event id and failure time" do
        sale = create(:sale, woo_store_id: "123")

        described_class.perform_now

        expect(Sale::ImportFailure.find_by!(store_name: "woo", store_order_id: "123")).to have_attributes(
          sale:, message: "boom", sentry_event_id: "event-1", last_failed_at: failed_at, failure_count: 1
        )
        expect(Sale::ImportFailure.find_by!(store_name: "woo", store_order_id: "456")).to have_attributes(
          sale_id: nil, message: "bang", sentry_event_id: "event-1"
        )
      end

      it "keeps recording without a Sentry event id" do
        allow(Sentry).to receive(:capture_exception).and_return(nil)

        described_class.perform_now

        expect(Sale::ImportFailure.pluck(:sentry_event_id)).to eq([nil, nil])
      end

      it "reports a recording failure, records the other orders, and stays discarded" do
        recording_error = ActiveRecord::StatementInvalid.new("cannot write")
        allow(Sale::ImportFailure).to receive(:record).and_call_original
        allow(Sale::ImportFailure).to receive(:record).with(hash_including(store_order_id: 123)).and_raise(recording_error)

        expect { described_class.perform_now }.not_to have_enqueued_job(described_class)

        expect(Sentry).to have_received(:capture_exception).with(recording_error, extra: {store_name: "woo", store_order_id: 123})
        expect(Sale::ImportFailure.pluck(:store_order_id)).to eq(["456"])
      end
    end

    it "retries the job after a deadlock" do
      allow(Sale::Woo::Pull).to receive(:run).and_raise(ActiveRecord::Deadlocked)

      expect { described_class.perform_now }.to have_enqueued_job(described_class)
    end
  end

  describe "Woo API failures" do
    let(:user) { create(:user) }
    let(:sentry_event) { instance_double(Sentry::ErrorEvent, event_id: "event-1") }
    let(:unavailable) { Woo::Api::Client::Unavailable.new("Woo is down", status: 502, url: "https://woo.test/orders/", body_preview: "<html>") }
    let(:jobs_link) { {label: "Open the jobs dashboard", href: "/jobs/statuses"} }

    before { allow(Sentry).to receive(:capture_exception).and_return(sentry_event) }

    context "when Woo cannot be reached" do
      before { allow(Sale::Woo::Pull).to receive(:run).and_raise(unavailable) }

      it "retries with the same arguments while attempts remain" do
        expect { described_class.perform_now(id: "123", requested_by: user) }
          .to have_enqueued_job(described_class).with(id: "123", requested_by: user)
      end

      it "stays quiet while attempts remain", :aggregate_failures do
        expect { described_class.perform_now(requested_by: user) }
          .not_to have_broadcasted_to(user).from_channel(NotificationsChannel)

        expect(Sentry).not_to have_received(:capture_exception)
      end

      it "gives up after five attempts, reports once, and alerts the requester once", :aggregate_failures do
        expect { perform_enqueued_jobs { described_class.perform_later(requested_by: user) } }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "WooCommerce did not respond, so nothing was pulled. Try again in a few minutes.", link: jobs_link)
          .exactly(:once)

        expect(Sale::Woo::Pull).to have_received(:run).exactly(5).times
        expect(Sentry).to have_received(:capture_exception)
          .with(unavailable, extra: {status: 502, url: "https://woo.test/orders/", body_preview: "<html>"}).once
      end

      it "records a pulled order as failed once attempts run out", :aggregate_failures do
        sale = create(:sale, woo_store_id: "123")

        perform_enqueued_jobs { described_class.perform_later(id: "123") }

        expect(Sale::ImportFailure.find_by!(store_name: "woo", store_order_id: "123")).to have_attributes(
          sale:, message: "Woo is down", sentry_event_id: "event-1", failure_count: 1, resolved_at: nil
        )
      end

      it "records nothing for a pull that is not about one order" do
        perform_enqueued_jobs { described_class.perform_later }

        expect(Sale::ImportFailure.count).to eq(0)
      end

      it "never tells the requester the pull finished", :aggregate_failures do
        expect { perform_enqueued_jobs { described_class.perform_later(requested_by: user) } }
          .not_to have_broadcasted_to(user).from_channel(NotificationsChannel).with(kind: "notice", message: "WooCommerce sales pull finished.")
      end
    end

    context "when Woo rejects the request" do
      let(:rejected) { Woo::Api::Client::Error.new("HTTP 401", status: 401, url: "https://woo.test/orders/", body_preview: "no") }

      before { allow(Sale::Woo::Pull).to receive(:run).and_raise(rejected) }

      it "does not retry, reports it, and alerts the requester", :aggregate_failures do
        expect { described_class.perform_now(id: "123", requested_by: user) }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "WooCommerce returned an unexpected response, so nothing was pulled.", link: jobs_link)

        expect(enqueued_jobs).to be_empty
        expect(Sentry).to have_received(:capture_exception)
          .with(rejected, extra: {status: 401, url: "https://woo.test/orders/", body_preview: "no"})
        expect(Sale::ImportFailure.count).to eq(0)
      end
    end

    context "when Woo has no such order" do
      before { allow(Sale::Woo::Pull).to receive(:run).and_raise(Woo::Api::Client::NotFound.new("gone", status: 404)) }

      it "tells the requester without leaving an unresolvable broken sale", :aggregate_failures do
        expect { described_class.perform_now(id: "123", requested_by: user) }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "This order was not found in WooCommerce.")

        expect(enqueued_jobs).to be_empty
        expect(Sale::ImportFailure.count).to eq(0)
      end
    end

    context "when something else breaks" do
      it "still tells the requester, without claiming what was or was not pulled" do
        allow(Sale::Woo::Pull).to receive(:run).and_raise(RuntimeError, "boom")

        expect { expect { described_class.perform_now(requested_by: user) }.to raise_error(RuntimeError, "boom") }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "The WooCommerce pull failed.", link: jobs_link)
      end
    end
  end

  describe "requester notifications" do
    let(:user) { create(:user) }

    it "tells the requester a sales pull finished" do
      expect { described_class.perform_now(limit: 100, requested_by: user) }
        .to have_broadcasted_to(user).from_channel(NotificationsChannel)
        .with(kind: "notice", message: "WooCommerce sales pull finished.")
    end

    it "tells the requester a single order pull finished" do
      expect { described_class.perform_now(id: "123", requested_by: user) }
        .to have_broadcasted_to(user).from_channel(NotificationsChannel)
        .with(kind: "notice", message: "WooCommerce order pull finished.")
    end

    it "tells the requester when some orders could not be pulled" do
      allow(Sale::Woo::Pull).to receive(:run).and_raise(Sale::Woo::Pull::Failed.new([]))
      allow(Sentry).to receive(:capture_exception)

      expect { described_class.perform_now(requested_by: user) }
        .to have_broadcasted_to(user).from_channel(NotificationsChannel)
        .with(kind: "alert", message: "Some WooCommerce orders could not be pulled.", link: {label: "Open broken sales", href: "/broken_sales"})
    end
  end
end
