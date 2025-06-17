class AddPurchaseIdToPurchaseItems < ActiveRecord::Migration[7.1]
  def change
    add_reference :purchase_items, :purchase, foreign_key: true
    remove_reference :purchase_items, :product
  end
end
