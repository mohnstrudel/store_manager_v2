class AddShopifyStatusFieldsToSales < ActiveRecord::Migration[8.0]
  def change
    add_column :sales, :fulfillment_status, :string
    add_column :sales, :financial_status, :string
    add_column :sales, :return_status, :string
    add_column :sales, :confirmed, :boolean, default: false
    add_column :sales, :closed, :boolean, default: false
    add_column :sales, :closed_at, :datetime
    add_column :sales, :cancelled_at, :datetime
    add_column :sales, :cancel_reason, :string
  end
end
