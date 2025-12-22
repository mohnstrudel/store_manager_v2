class RemovePriceFromStoreInfos < ActiveRecord::Migration[8.1]
  def change
    safety_assured { remove_column :store_infos, :price, :decimal }
  end
end
