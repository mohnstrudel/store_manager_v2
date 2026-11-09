# frozen_string_literal: true

class Purchases::FormResource < ApplicationResource
  typelize({
    id: "number | null",
    path: :string,
    product_id: "number | null",
    variant_id: "number | null",
    supplier_id: "number | null",
    order_reference: :string,
    item_price: :string,
    amount: :string,
    warehouse_id: "number | null",
    payment_value: :string,
    variant_availability: "VariantAvailability | null"
  })
  attribute :purchase do |page|
    purchase = page.fetch(:purchase)
    product = purchase_display_product(purchase)

    {
      id: purchase.id,
      path: purchase.persisted? ? purchase_path(purchase) : "",
      product_id: product&.id,
      variant_id: purchase.variant_id,
      supplier_id: purchase.supplier_id,
      order_reference: purchase.order_reference.to_s,
      item_price: decimal_field_value(purchase.item_price),
      amount: purchase.amount.to_s,
      warehouse_id: purchase.warehouse_id,
      payment_value: decimal_field_value(purchase.payment_value),
      variant_availability: product && VariantAvailabilityResource.new(product, params: {current_variant: purchase.variant}).serializable_hash
    }
  end

  typelize({
    products: "Array<{ value: number; label: string }>",
    suppliers: "Array<{ value: number; label: string }>",
    warehouses: "Array<{ value: number; label: string }>"
  })
  attribute :options do |page|
    {
      products: page.fetch(:products).map { |product| {value: product.id, label: product.build_full_title_with_shop_id} },
      suppliers: page.fetch(:suppliers).map { |supplier| {value: supplier.id, label: supplier.title} },
      warehouses: page.fetch(:warehouses).map { |warehouse| {value: warehouse.id, label: warehouse.name} }
    }
  end
end
