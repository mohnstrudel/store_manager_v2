class AddVariationToSaleItem < ActiveRecord::Migration[7.1]
  def change
    add_reference :sale_items, :variation, foreign_key: true
  end
end
