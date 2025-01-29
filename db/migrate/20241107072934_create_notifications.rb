class CreateNotifications < ActiveRecord::Migration[7.2]
  def change
    create_table :notifications do |t|
      t.string :name, null: false
      t.integer :event_type, null: false, default: 0
      t.integer :status, null: false, default: 0  # disabled: 0, active: 1
      t.references :email_template, null: false, foreign_key: true

      t.timestamps
    end

    add_index :notifications, [:event_type, :status]
  end
end
