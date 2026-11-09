# frozen_string_literal: true

class WarehouseResource < ApplicationResource
  typelize_from Warehouse

  attributes :id

  typelize :string
  attribute :name, &:name

  typelize :boolean
  attribute :is_default, &:is_default?

  typelize({progress: :number, paid: :string, price: :string, debt: "string | null"})
  attribute :payment_progress do |warehouse|
    {
      progress: warehouse.average_payment_progress.to_f,
      paid: "",
      price: "",
      debt: format_money(warehouse.total_debt)
    }
  end
end
