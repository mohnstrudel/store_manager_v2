# frozen_string_literal: true

class RemoveDescriptionFromProducts < ActiveRecord::Migration[8.1]
  def up
    # Remove the description column as we're moving to Action Text
    # Data migration is handled by Action Text when records are saved
    safety_assured { remove_column :products, :description, :text }
  end

  def down
    add_column :products, :description, :text
  end
end
