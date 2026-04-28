# frozen_string_literal: true

class DropUniqueIndexOnEditionsSku < ActiveRecord::Migration[8.1]
  def change
    remove_index :editions, :sku if index_exists?(:editions, :sku, unique: true)
    add_index :editions, :sku unless index_exists?(:editions, :sku)
  end
end
