# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouse::Financials do
  describe "#average_payment_progress" do
    it "returns 0 when the warehouse has no purchases" do
      warehouse = create(:warehouse)

      expect(warehouse.average_payment_progress).to eq(0)
    end

    it "averages purchase progress and rounds the result" do
      warehouse = create(:warehouse)
      create(:purchase, warehouse_id: warehouse.id)
      create(:purchase, warehouse_id: warehouse.id)

      expect(warehouse.average_payment_progress).to eq(0)
    end
  end

  describe "#total_debt" do
    it "returns the rounded total debt for the warehouse purchases" do
      warehouse = create(:warehouse)

      expect(warehouse.total_debt).to eq(0)
    end
  end
end
