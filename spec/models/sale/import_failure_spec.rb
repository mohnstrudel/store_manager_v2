# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: sale_import_failures
#
#  id              :bigint           not null, primary key
#  failure_count   :integer          default(0), not null
#  first_failed_at :datetime         not null
#  last_failed_at  :datetime         not null
#  message         :text             not null
#  resolved_at     :datetime
#  store_name      :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  sale_id         :bigint
#  sentry_event_id :string
#  store_order_id  :string           not null
#
RSpec.describe Sale::ImportFailure, :aggregate_failures do
  let(:store_order_id) { "gid://shopify/Order/123" }
  let(:failed_at) { Time.zone.local(2026, 11, 9, 12) }

  def record_failure(**overrides)
    described_class.record(
      store_name: "shopify",
      store_order_id:,
      message: "boom",
      sentry_event_id: "event-1",
      failed_at:,
      **overrides
    )
  end

  def stored_failure
    described_class.find_by!(store_name: "shopify", store_order_id:)
  end

  describe ".record" do
    it "creates one row with the failure details" do
      record_failure

      expect(stored_failure).to have_attributes(
        message: "boom",
        sentry_event_id: "event-1",
        failure_count: 1,
        first_failed_at: failed_at,
        last_failed_at: failed_at,
        resolved_at: nil,
        sale_id: nil
      )
    end

    it "keeps a failure without a Sentry event id" do
      record_failure(sentry_event_id: nil)

      expect(stored_failure.sentry_event_id).to be_nil
    end

    it "links the Shopify sale when it exists" do
      sale = create(:sale, shopify_store_id: store_order_id)

      record_failure

      expect(stored_failure.sale).to eq(sale)
    end

    it "links the Woo sale when it exists" do
      sale = create(:sale, woo_store_id: "456")

      described_class.record(store_name: "woo", store_order_id: 456, message: "boom", sentry_event_id: nil, failed_at:)

      expect(described_class.find_by!(store_name: "woo", store_order_id: "456").sale).to eq(sale)
    end

    it "keeps separate rows for the same id in different stores" do
      record_failure(store_order_id: "456")
      record_failure(store_name: "woo", store_order_id: "456")

      expect(described_class.where(store_order_id: "456").count).to eq(2)
    end

    it "increments the same row when the order fails again" do
      later = failed_at + 1.hour
      record_failure
      record_failure(message: "boom again", sentry_event_id: "event-2", failed_at: later)

      expect(described_class.count).to eq(1)
      expect(stored_failure).to have_attributes(
        message: "boom again",
        sentry_event_id: "event-2",
        failure_count: 2,
        first_failed_at: failed_at,
        last_failed_at: later
      )
    end

    it "starts a new failure history when the failure is newer than the row's resolution" do
      record_failure
      record_failure(failed_at: failed_at + 30.minutes)
      stored_failure.update!(resolved_at: failed_at + 1.hour)

      record_failure(message: "boom again", failed_at: failed_at + 2.hours)

      expect(stored_failure).to have_attributes(
        message: "boom again",
        resolved_at: nil,
        failure_count: 1,
        first_failed_at: failed_at + 2.hours,
        last_failed_at: failed_at + 2.hours
      )
    end

    it "keeps counting from the reopened failure" do
      record_failure
      stored_failure.update!(resolved_at: failed_at + 1.hour)
      record_failure(failed_at: failed_at + 2.hours)

      record_failure(failed_at: failed_at + 3.hours)

      expect(stored_failure).to have_attributes(
        failure_count: 2,
        first_failed_at: failed_at + 2.hours,
        last_failed_at: failed_at + 3.hours
      )
    end

    it "ignores a failure older than the row's resolution" do
      record_failure
      resolved_at = failed_at + 2.hours
      stored_failure.update!(resolved_at:)

      record_failure(message: "stale", sentry_event_id: "event-2", failed_at: failed_at + 1.hour)

      expect(stored_failure).to have_attributes(
        message: "boom",
        sentry_event_id: "event-1",
        failure_count: 1,
        last_failed_at: failed_at,
        resolved_at:
      )
    end

    it "enforces one row per store order in the database" do
      record_failure

      expect {
        described_class.new(stored_failure.attributes.except("id")).save!
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe ".record_safely" do
    let(:attributes) do
      {store_name: "shopify", store_order_id:, message: "boom", sentry_event_id: "event-1", failed_at:}
    end

    it "records the failure" do
      described_class.record_safely(**attributes)

      expect(stored_failure.failure_count).to eq(1)
    end

    it "reports a recording error to Sentry instead of raising it" do
      error = ActiveRecord::StatementInvalid.new("cannot write")
      allow(described_class).to receive(:record).and_raise(error)
      allow(Sentry).to receive(:capture_exception)

      expect { described_class.record_safely(**attributes) }.not_to raise_error

      expect(Sentry).to have_received(:capture_exception).with(
        error,
        extra: {store_name: "shopify", store_order_id:}
      )
    end
  end

  describe ".last_failed_before" do
    it "keeps the failures whose last failure predates the time" do
      record_failure(store_order_id: "gid://shopify/Order/old", failed_at: failed_at)
      record_failure(store_order_id: "gid://shopify/Order/at", failed_at: failed_at + 1.hour)
      record_failure(store_order_id: "gid://shopify/Order/new", failed_at: failed_at + 2.hours)

      expect(described_class.last_failed_before(failed_at + 1.hour).pluck(:store_order_id)).to eq(["gid://shopify/Order/old"])
    end
  end

  describe "#pull_later" do
    include ActiveJob::TestHelper

    let(:user) { create(:user) }

    it "queues a Shopify order pull by store order id" do
      record_failure

      expect { stored_failure.pull_later }.to have_enqueued_job(Shopify::PullSaleJob).with(store_order_id)
    end

    it "queues a Woo order pull by store order id" do
      record_failure(store_name: "woo", store_order_id: "77")
      woo_failure = described_class.find_by!(store_name: "woo", store_order_id: "77")

      expect { woo_failure.pull_later }.to have_enqueued_job(Woo::PullSalesJob).with(id: "77")
    end

    it "tells the Shopify pull who asked for it" do
      record_failure

      expect { stored_failure.pull_later(requested_by: user) }
        .to have_enqueued_job(Shopify::PullSaleJob).with(store_order_id, requested_by: user)
    end

    it "tells the Woo pull who asked for it" do
      record_failure(store_name: "woo", store_order_id: "77")
      woo_failure = described_class.find_by!(store_name: "woo", store_order_id: "77")

      expect { woo_failure.pull_later(requested_by: user) }
        .to have_enqueued_job(Woo::PullSalesJob).with(id: "77", requested_by: user)
    end
  end

  describe ".pull_unresolved_later" do
    include ActiveJob::TestHelper

    let(:user) { create(:user) }

    it "queues one pull per unresolved failure of the sales, for the requester, and counts them" do
      sale = create(:sale, shopify_store_id: store_order_id)
      record_failure
      resolved_sale = create(:sale, shopify_store_id: "gid://shopify/Order/456")
      record_failure(store_order_id: "gid://shopify/Order/456")
      described_class.resolve(store_name: "shopify", store_order_id: "gid://shopify/Order/456")
      create(:sale, shopify_store_id: "gid://shopify/Order/789")
      record_failure(store_order_id: "gid://shopify/Order/789")

      queued = described_class.pull_unresolved_later(sale_ids: [sale.id, resolved_sale.id], requested_by: user)

      expect(queued).to eq(1)
      expect(enqueued_jobs.size).to eq(1)
      expect(Shopify::PullSaleJob).to have_been_enqueued.with(store_order_id, requested_by: user).once
    end
  end

  describe ".resolve" do
    it "sets resolved_at on the unresolved row" do
      record_failure

      freeze_time do
        described_class.resolve(store_name: "shopify", store_order_id:)

        expect(stored_failure.resolved_at).to eq(Time.current)
      end
    end

    it "keeps the first resolution time" do
      record_failure
      resolved_at = failed_at + 1.hour
      stored_failure.update!(resolved_at:)

      described_class.resolve(store_name: "shopify", store_order_id:)

      expect(stored_failure.resolved_at).to eq(resolved_at)
    end

    it "is a no-op without a row" do
      expect {
        described_class.resolve(store_name: "shopify", store_order_id:)
      }.not_to change(described_class, :count)
    end
  end
end
