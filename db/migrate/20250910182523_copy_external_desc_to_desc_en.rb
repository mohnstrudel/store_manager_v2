class CopyExternalDescToDescEn < ActiveRecord::Migration[8.0]
  def up
    # Copy data from external_desc to desc_en for all warehouses
    safety_assured {
      execute <<-SQL.squish
        UPDATE warehouses
        SET desc_en = external_desc
        WHERE external_desc IS NOT NULL;
      SQL
      remove_column :warehouses, :external_desc
    }
  end

  def down
    # No need to do anything in the down direction as we're just copying data
  end
end
