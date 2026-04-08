class AddChecksumAndAltTextToStoreInfos < ActiveRecord::Migration[8.1]
  def change
    change_table :store_infos, bulk: true do |t|
      t.string :checksum
      t.string :alt_text
    end
  end
end
