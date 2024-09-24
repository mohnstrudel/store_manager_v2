class AddPurchaseIdToPurchasedProducts < ActiveRecord::Migration[7.1]
  def change
    add_reference :purchased_products, :purchase, foreign_key: true
    remove_reference :purchased_products, :product
  end
end
