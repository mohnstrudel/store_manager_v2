class AddPurchaseReferencesToPayment < ActiveRecord::Migration[7.0]
  def change
    add_reference :payments, :purchase, null: false, foreign_key: true # rubocop:todo Rails/NotNullColumn
  end
end
