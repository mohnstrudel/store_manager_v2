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
