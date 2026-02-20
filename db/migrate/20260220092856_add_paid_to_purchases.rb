# frozen_string_literal: true

class AddPaidToPurchases < ActiveRecord::Migration[8.1]
  def change
    change_column_default :payments, :value, from: nil, to: 0.00
    add_column :purchases, :paid, :decimal, precision: 8, scale: 2, null: false, default: 0.00

    backfill_paid_with_payments
  end

  def backfill_paid_with_payments
    Purchase.joins(:payments).update_all(<<~SQL.squish)
      paid = COALESCE((
        SELECT SUM(payments.value)
        FROM payments
        WHERE payments.purchase_id = purchases.id
      ), 0)
    SQL
  end
end
