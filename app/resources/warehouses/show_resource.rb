# frozen_string_literal: true

class Warehouses::ShowResource < ApplicationResource
  typelize "WarehousesDetail"
  attribute :warehouse do |page|
    Warehouses::DetailResource.new(page.fetch(:warehouse)).serializable_hash
  end

  typelize "Array<WarehousesPurchaseItem>"
  attribute :purchase_items do |page|
    Warehouses::PurchaseItemResource.new(page.fetch(:purchase_items)).serializable_hash
  end

  typelize "Pagination"
  attribute :pagination do |page|
    PaginationResource.for(page.fetch(:purchase_items))
  end

  typelize({q: :string})
  attribute :search do |page|
    {q: page.fetch(:query)}
  end

  typelize :number, nullable: true
  attribute :selected_id do |page|
    page.fetch(:selected_id)
  end

  typelize :number
  attribute :total_purchase_items do |page|
    page.fetch(:total_purchase_items)
  end

  typelize "Array<WarehouseOption>"
  attribute :warehouses do |_page|
    WarehouseOptionResource.new(Warehouse.order(name: :asc)).serializable_hash
  end

  typelize "Array<ShippingCompanyOption>"
  attribute :shipping_companies do |_page|
    ShippingCompanyOptionResource.new(ShippingCompany.ordered).serializable_hash
  end

  typelize :string
  attribute :warehouse_move_path do |page|
    warehouse_move_path(warehouse_id: page.fetch(:warehouse).id)
  end
end
