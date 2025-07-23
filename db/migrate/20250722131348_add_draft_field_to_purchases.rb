class AddDraftFieldToPurchases < ActiveRecord::Migration[8.0]
  def change
    add_column :purchases, :draft, :boolean, null: false, default: true
  end
end
