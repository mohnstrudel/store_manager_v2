class AddAccessScopesToShops < ActiveRecord::Migration[8.0]
  def change
    add_column :shops, :access_scopes, :string
  end
end
