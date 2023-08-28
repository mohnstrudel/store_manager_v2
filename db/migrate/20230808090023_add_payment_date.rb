class AddPaymentDate < ActiveRecord::Migration[7.0]
  def change
    add_column :payments, :payment_date, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
  end
end
