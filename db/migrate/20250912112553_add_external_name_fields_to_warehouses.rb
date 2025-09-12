class AddExternalNameFieldsToWarehouses < ActiveRecord::Migration[8.0]
  def change
    safety_assured {
      change_table :warehouses, bulk: true do |t|
        t.string :external_name_de
        t.string :external_name_en
      end

      reversible do |dir|
        dir.up do
          execute <<-SQL.squish
            UPDATE warehouses 
            SET external_name_en = external_name 
            WHERE external_name IS NOT NULL
          SQL
        end
      end
    }
  end
end
