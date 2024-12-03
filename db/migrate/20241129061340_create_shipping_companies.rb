class CreateShippingCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :shipping_companies do |t|
      t.string :name
      t.string :tracking_url

      t.timestamps
    end
    add_index :shipping_companies, :name, unique: true
  end
end
