class AddNameToUsers < ActiveRecord::Migration[8.0]
  def change
    # "safety_assured" block is strong_migrations requirement
    safety_assured do
      change_table :users, bulk: true do |t|
        t.string :first_name
        t.string :last_name
      end
    end
  end
end
