class CreateCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :customers do |t|
      t.string :woo_id
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
  end
end
