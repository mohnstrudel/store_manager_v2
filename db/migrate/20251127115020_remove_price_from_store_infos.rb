class RemovePriceFromStoreInfos < ActiveRecord::Migration[8.1]
  def change
    remove_column :store_infos, :price, :decimal
  end
end
