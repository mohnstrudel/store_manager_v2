# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveStorage::Blob::ReclamationJob do
  it "uses the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end

  it "delegates reclamation to the model-owned command" do
    cutoff = 30.days.ago.change(usec: 0)
    allow(ActiveStorage::Blob::Reclamation).to receive(:apply!)

    described_class.perform_now(cutoff: cutoff.iso8601)

    expect(ActiveStorage::Blob::Reclamation).to have_received(:apply!).with(cutoff:)
  end
end
