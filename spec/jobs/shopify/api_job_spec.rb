# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::ApiJob do
  include ActiveJob::TestHelper

  let(:retry_after) { nil }
  let(:job_class) do
    error = Shopify::Api::Client::Throttled.new("throttled", retry_after:)

    Class.new(described_class) do
      define_method(:perform) { |*| raise error }
    end
  end

  before { stub_const("ThrottledApiJob", job_class) }

  def waits
    enqueued_jobs.map { |job| Time.zone.at(job[:at]) - Time.current }
  end

  def throttle_through(attempts)
    job_class.new("gid://shopify/Order/1", cursor: "abc").perform_now
    (attempts - 1).times { ActiveJob::Base.execute(enqueued_jobs.last) }
  end

  it "retries a throttled call 9 times with the same arguments, then lets the error through" do
    freeze_time do
      throttle_through(9)

      expect { ActiveJob::Base.execute(enqueued_jobs.last) }.to raise_error(Shopify::Api::Client::Throttled)

      expect(enqueued_jobs.size).to eq(9)
      expect(enqueued_jobs.pluck(:args).uniq.size).to eq(1)
    end
  end

  context "when Shopify reports how long its budget needs to restore" do
    let(:retry_after) { 8.5 }

    it "waits that long plus up to a quarter, on every attempt" do
      freeze_time do
        throttle_through(5)

        expect(waits).to all(be_between(8.5, 8.5 * 1.25))
      end
    end
  end

  context "when Shopify's budget is already restored" do
    let(:retry_after) { 0.0 }

    it "still waits a second before asking again" do
      freeze_time do
        throttle_through(2)

        expect(waits).to all(be_between(1, 1 * 1.25))
      end
    end
  end

  context "when Shopify reports a wait longer than a minute" do
    let(:retry_after) { 7200.0 }

    it "waits a minute" do
      freeze_time do
        throttle_through(2)

        expect(waits).to all(be_between(60, 60 * 1.25))
      end
    end
  end

  context "when Shopify reports no wait" do
    it "doubles the wait from 2 seconds up to a minute, with up to a quarter on top" do
      freeze_time do
        throttle_through(9)

        expect(waits.zip([2, 4, 8, 16, 32, 60, 60, 60, 60])).to all(satisfy { |wait, base| wait.between?(base, base * 1.25) })
      end
    end
  end

  it "leaves the wait of other retried errors alone" do
    error_job = Class.new(described_class) do
      retry_on ArgumentError, wait: 10.seconds, attempts: 2, jitter: 0
      define_method(:perform) { |*| raise ArgumentError, "boom" }
    end
    stub_const("ArgumentErrorApiJob", error_job)

    freeze_time do
      error_job.perform_now

      expect(waits).to eq([10])
    end
  end
end
