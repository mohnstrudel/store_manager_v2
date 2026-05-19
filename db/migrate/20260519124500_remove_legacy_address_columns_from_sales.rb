# frozen_string_literal: true

class RemoveLegacyAddressColumnsFromSales < ActiveRecord::Migration[8.1]
  def change
    remove_columns :sales,
      :address_1,
      :address_2,
      :city,
      :company,
      :country,
      :postcode,
      :state,
      type: :string
  end
end
