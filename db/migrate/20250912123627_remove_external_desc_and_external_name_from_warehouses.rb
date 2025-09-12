class RemoveExternalDescAndExternalNameFromWarehouses < ActiveRecord::Migration[8.0]
  def change
    safety_assured do
      remove_columns :warehouses, :external_desc, :external_name, type: :string, bulk: true
    end
  end
end
