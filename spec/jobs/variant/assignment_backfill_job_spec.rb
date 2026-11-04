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

  it "raises a named error carrying every failure and describing at most the first ten" do
    failures = Array.new(12) { |i| {id: i} }
    stub_backfill(failures)

    expect { described_class.perform_now }.to raise_error(Variant::AssignmentBackfill::Failed) { |error|
      expect(error.failures).to eq(failures)
      expect(error.message).to include("12 failure(s)", "{id: 9}", "(and 2 more)")
      expect(error.message).not_to include("{id: 10}")
    }
  end
end
