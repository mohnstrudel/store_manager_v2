class AddShippingCompanyToPurchaseItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :purchase_items, :shipping_company, foreign_key: true
  end
end
