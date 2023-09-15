class AddPhoneAndEmailToCustomers < ActiveRecord::Migration[7.0]
  def change
    change_table :customers, bulk: true do |t|
      t.string :email
      t.string :phone
    end
    remove_column :sales, :phone, :string
  end
end
