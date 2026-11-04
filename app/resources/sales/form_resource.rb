# frozen_string_literal: true

class Sales::FormResource < ApplicationResource
  typelize({
    id: "number | null",
    path: :string,
    status: "string | null",
    customer_id: "number | null",
    note: "string | null",
    total: :string,
    discount_total: :string,
    shipping_total: :string,
    shipping_address: "SalesFormAddress",
    billing_address: "SalesFormAddress",
    sale_items: "Array<SalesFormItem>"
  })
  attribute :sale do |page|
    sale = page.fetch(:sale)

    {
      id: sale.id,
      path: sale.persisted? ? sale_path(sale) : "",
      status: sale.status,
      customer_id: sale.customer_id,
      note: sale.note,
      total: sale.total.to_s,
      discount_total: sale.discount_total.to_s,
      shipping_total: sale.shipping_total.to_s,
      shipping_address: form_address(sale.shipping_address),
      billing_address: form_address(sale.billing_address),
      sale_items: Sales::FormItemResource.new(sale.sale_items).serializable_hash
    }
  end

  typelize({
    customers: "Array<{ value: number; label: string }>",
    products: "Array<{ value: number; label: string }>",
    status_names: "Array<string>"
  })
  attribute :options do |_page|
    {
      customers: Customer.order(:email).map { |customer| {value: customer.id, label: customer.name_and_email} },
      products: Product.with_store_references.map { |product| {value: product.id, label: product.build_full_title_with_shop_id} },
      status_names: Sale::STATUSES
    }
  end

  def form_address(address)
    Sales::FormAddressResource.new(address || SaleAddress.new).serializable_hash
  end
end
