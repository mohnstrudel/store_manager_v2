# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::ApiJob do
  include ActiveJob::TestHelper

  let(:job_class) do
    Class.new(described_class) do
      def perform(*)
        raise Shopify::Api::Client::Throttled
      end
    end
  end

  before { stub_const("ThrottledApiJob", job_class) }

  it "retries a throttled call 9 times with growing waits and the same arguments, then lets the error through" do
    freeze_time do
      job_class.new("gid://shopify/Order/1", cursor: "abc").perform_now
      8.times { ActiveJob::Base.execute(enqueued_jobs.last) }

      expect { ActiveJob::Base.execute(enqueued_jobs.last) }.to raise_error(Shopify::Api::Client::Throttled)

      waits = enqueued_jobs.map { |job| Time.zone.at(job[:at]) - Time.current }
      expect(enqueued_jobs.size).to eq(9)
      expect(enqueued_jobs.pluck(:args).uniq.size).to eq(1)
      expect(waits.each_cons(2)).to all(satisfy { |earlier, later| later > earlier })
    end
  end
end
