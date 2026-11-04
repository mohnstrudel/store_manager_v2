# frozen_string_literal: true

class Products::FormResource < ApplicationResource
  typelize "ProductsFormProduct"
  attribute :product do |page|
    Products::FormProductResource.new(page.fetch(:product)).serializable_hash
  end

  typelize({
    franchises: "Array<{ value: number; label: string }>",
    brands: "Array<{ value: number; label: string }>",
    shapes: "Array<string>",
    sizes: "Array<{ value: number; label: string }>",
    versions: "Array<{ value: number; label: string }>",
    colors: "Array<{ value: number; label: string }>",
    suppliers: "Array<{ value: number; label: string }>",
    warehouses: "Array<{ value: number; label: string }>",
    store_names: "Array<string>"
  })
  attribute :options do |_page|
    {
      franchises: select_options(Franchise.order(:title), :title),
      brands: select_options(Brand.order(:title), :title),
      shapes: Product.shape_options,
      sizes: select_options(Size.order(:value), :value),
      versions: select_options(Version.order(:value), :value),
      colors: select_options(Color.order(:value), :value),
      suppliers: select_options(Supplier.order(:title), :title),
      warehouses: select_options(Warehouse.order(:name), :name),
      store_names: StoreInfo.assignable_store_names
    }
  end

  def select_options(records, label)
    records.map { |record| {value: record.id, label: record.public_send(label)} }
  end
end
