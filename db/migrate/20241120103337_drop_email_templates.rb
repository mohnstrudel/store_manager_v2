class DropEmailTemplates < ActiveRecord::Migration[8.0]
  def up
    drop_table :email_templates
  end

  def down
    create_table :email_templates do |t|
      t.string :name, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.integer :status, null: false, default: 2

      t.timestamps
    end

    add_index :email_templates, :name, unique: true
    add_index :email_templates, :status
  end
end
