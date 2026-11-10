# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::AssignmentBackfillJob do
  def stub_backfill(failures)
    result = instance_double(Variant::AssignmentBackfill::Result, failures:)
    allow(Variant::AssignmentBackfill).to receive(:call).with(env: {"APPLY" => "1"}).and_return(result)
  end

  it "does nothing when the backfill records no failures" do
    stub_backfill([])

    expect { described_class.perform_now }.not_to raise_error
  end

  it "reports a named error carrying every failure and describing at most the first ten, then discards the job", :aggregate_failures do
    failures = Array.new(12) { |i| {id: i} }
    stub_backfill(failures)
    allow(Sentry).to receive(:capture_exception)

    expect { described_class.perform_now }.not_to raise_error

    expect(Sentry).to have_received(:capture_exception) { |error|
      expect(error).to be_a(Variant::AssignmentBackfill::Failed)
      expect(error.failures).to eq(failures)
      expect(error.message).to include("12 failure(s)", "{id: 9}", "(and 2 more)")
      expect(error.message).not_to include("{id: 10}")
    }
  end

  describe "requester notifications" do
    let(:user) { create(:user) }

    it "tells the requester the repair finished" do
      stub_backfill([])

      expect { described_class.perform_now(requested_by: user) }
        .to have_broadcasted_to(user).from_channel(NotificationsChannel)
        .with(kind: "notice", message: "Broken sales repair finished.")
    end

    it "tells the requester some sales could not be repaired" do
      stub_backfill([{id: 1}])
      allow(Sentry).to receive(:capture_exception)

      expect { described_class.perform_now(requested_by: user) }
        .to have_broadcasted_to(user).from_channel(NotificationsChannel)
        .with(kind: "alert", message: "Some broken sales could not be repaired.", link: {label: "Open broken sales", href: "/broken_sales"})
    end

    it "notifies nobody when no requester is given" do
      stub_backfill([])

      expect { described_class.perform_now }.not_to have_broadcasted_to(user).from_channel(NotificationsChannel)
    end
  end
end
