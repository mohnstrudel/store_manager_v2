# frozen_string_literal: true

class AddExtCreatedAtAndExtUpdatedAtToStoreInfos < ActiveRecord::Migration[8.1]
  def change
    change_table :store_infos, bulk: true do |t|
      t.datetime :ext_created_at
      t.datetime :ext_updated_at
    end
  end
end
