class CreateEmailTemplates < ActiveRecord::Migration[7.2]
  def change
    create_table :email_templates do |t|
      t.string :name, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.integer :status, null: false, default: 2  # disabled: 0, active: 1, draft: 2

      t.timestamps
    end

    add_index :email_templates, :name, unique: true
    add_index :email_templates, :status
  end
end
