# frozen_string_literal: true

module SupplierHelper
  def supplier_form_props(supplier)
    {
      supplier: supplier_props(supplier)
    }
  end

  def supplier_props(supplier)
    {
      id: supplier.id,
      title: supplier.title.to_s,
      created_at: formatted_timestamp(supplier.created_at),
      updated_at: formatted_timestamp(supplier.updated_at)
    }
  end

  def supplier_purchase_props(purchase)
    {
      amount: purchase.amount,
      debt: purchase.debt.positive? ? format_money(purchase.debt) : nil,
      has_debt: purchase.debt.positive?,
      id: purchase.id,
      item_price: format_money(purchase.item_price),
      path: purchase_path(purchase),
      purchased_ago: time_ago_in_words(purchase.date),
      title: purchase_product_title(purchase),
      variant: purchase.variant&.title.to_s
    }
  end
end
