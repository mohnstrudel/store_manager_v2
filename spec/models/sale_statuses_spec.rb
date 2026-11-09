# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale do
  describe "#active?" do
    it "returns true for active statuses" do
      sale = create(:sale, status: described_class::ACTIVE_STATUSES.first)

      expect(sale.active?).to be true
    end
  end

  describe "#completed?" do
    it "returns true for completed statuses" do
      sale = create(:sale, status: described_class::COMPLETED_STATUSES.first)

      expect(sale.completed?).to be true
    end
  end
end
