# frozen_string_literal: true

class AddSourceUrlToStoreInfos < ActiveRecord::Migration[8.1]
  def change
    add_column :store_infos, :source_url, :string
  end
end
