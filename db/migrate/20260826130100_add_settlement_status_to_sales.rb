# frozen_string_literal: true

class AddSettlementStatusToSales < ActiveRecord::Migration[8.1]
  def change
    add_column :sales, :settlement_status, :string

    add_check_constraint :sales,
      "settlement_status IN ('paid', 'not_fully_paid', 'unknown')",
      name: "sales_settlement_status_allowed_values"
  end
end
