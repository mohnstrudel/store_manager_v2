class AddVariationReferencesToPurchases < ActiveRecord::Migration[7.1]
  def change
    add_reference :purchases, :variation, foreign_key: true
    change_column_null :purchases, :product_id, true
  end
end
