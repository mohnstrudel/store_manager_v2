class AddSaleItemRefToPurchaseItems < ActiveRecord::Migration[7.1]
  def change
    add_reference :purchase_items, :sale_item, foreign_key: true
  end
end
