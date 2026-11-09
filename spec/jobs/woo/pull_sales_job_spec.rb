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

    it "reports failed orders to Sentry and discards the job instead of retrying" do
      failures = [Sale::Woo::Pull::Failure.new(woo_id: 123, message: "boom")]
      allow(Sale::Woo::Pull).to receive(:run).and_raise(Sale::Woo::Pull::Failed.new(failures))
      allow(Sentry).to receive(:capture_exception)

      expect { described_class.perform_now }.not_to have_enqueued_job(described_class)

      expect(Sentry).to have_received(:capture_exception).with(
        an_instance_of(Sale::Woo::Pull::Failed),
        extra: {failed_woo_order_ids: [123]}
      )
    end

    it "retries the job after a deadlock" do
      allow(Sale::Woo::Pull).to receive(:run).and_raise(ActiveRecord::Deadlocked)

      expect { described_class.perform_now }.to have_enqueued_job(described_class)
    end
  end
end
