class AddShippingCompanyToPurchasedProducts < ActiveRecord::Migration[8.0]
  def change
    add_reference :purchased_products, :shipping_company, foreign_key: true
  end
end
