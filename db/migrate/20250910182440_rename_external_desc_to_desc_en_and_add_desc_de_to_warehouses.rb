class RenameExternalDescToDescEnAndAddDescDeToWarehouses < ActiveRecord::Migration[8.0]
  def change
    # Step 1: Add new column desc_en
    add_column :warehouses, :desc_en, :string # rubocop:todo Rails/BulkChangeTable

    # Step 2: Add new column desc_de
    add_column :warehouses, :desc_de, :string

    # Step 3: Copy data from external_desc to desc_en
    # This will be done in a separate data migration to avoid long-running transactions
  end
end
