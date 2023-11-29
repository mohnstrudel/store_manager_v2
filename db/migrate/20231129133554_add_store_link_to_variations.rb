class AddStoreLinkToVariations < ActiveRecord::Migration[7.1]
  def change
    add_column :variations, :store_link, :string
  end
end
