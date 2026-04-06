# frozen_string_literal: true

require "rails_helper"

RSpec.describe Warehouse do
  describe "#destroy_if_empty!" do
    it "destroys an empty warehouse" do
      warehouse = create(:warehouse)

      expect {
        warehouse.destroy_if_empty!
      }.to change(Warehouse, :count).by(-1)
    end

    it "raises a validation error when the warehouse still has purchase items" do
      warehouse = create(:warehouse)
      create(:purchase_item, warehouse:)

      expect {
        warehouse.destroy_if_empty!
      }.to raise_error(ActiveRecord::RecordInvalid, /move out all purchased products/)

      expect(warehouse.errors[:base]).to include(
        "Error. Please select and move out all purchased products before deleting the warehouse"
      )
    end
  end
end
