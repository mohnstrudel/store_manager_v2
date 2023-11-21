class AddStoreLinkToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :store_link, :string
  end
end
