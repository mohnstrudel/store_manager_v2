# frozen_string_literal: true

class PurchaseItems::FormPageResource < ApplicationResource
  typelize "PurchaseItemsFormRecord"
  attribute :purchase_item do |page|
    PurchaseItems::FormRecordResource.new(
      page.fetch(:purchase_item),
      params: {redirect_to_sale_item: page.fetch(:redirect_to_sale_item, false)}
    ).serializable_hash
  end

  typelize({
    warehouses: "Array<{ value: number; label: string }>",
    purchases: "Array<{ value: number; label: string }>",
    shipping_companies: "Array<{ value: number; label: string }>"
  })
  attribute :options do |_page|
    {
      warehouses: Rails.cache.fetch(["pif/warehouses", Warehouse.maximum(:updated_at)]) {
        Warehouse.order(:name).pluck(:id, :name).map { |id, name| {value: id, label: name} }
      },
      purchases: Rails.cache.fetch(["pif/purchases", Purchase.maximum(:updated_at)]) {
        purchase_options
      },
      shipping_companies: Rails.cache.fetch(["pif/shipping_companies", ShippingCompany.maximum(:updated_at)]) {
        ShippingCompany.order(:name).pluck(:id, :name).map { |id, name| {value: id, label: name} }
      }
    }
  end

  def purchase_options
    Purchase
      .joins(:supplier)
      .left_outer_joins(:product)
      .order(purchase_date: :desc, created_at: :desc)
      .pluck(:id, "suppliers.title", "products.full_title",
        Arel.sql("COALESCE(purchases.purchase_date, purchases.created_at)"))
      .map { |id, supplier, product, date|
        {value: id, label: "#{supplier} | #{product} | #{date&.strftime("%Y-%m-%d")}"}
      }
  end
end
