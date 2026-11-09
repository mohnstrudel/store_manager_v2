# frozen_string_literal: true

class Purchases::PurchaseItemResource < ApplicationResource
  typelize_from PurchaseItem

  attributes :id

  typelize :string
  attribute :path do |purchase_item|
    purchase_item_path(purchase_item)
  end

  typelize :string
  attribute :edit_path do |purchase_item|
    edit_purchase_item_path(purchase_item)
  end

  typelize :string
  attribute :unlink_path do |purchase_item|
    purchase_item_sale_item_link_path(purchase_item)
  end

  typelize :string
  attribute :warehouse_name do |purchase_item|
    purchase_item.warehouse.name
  end

  typelize :string
  attribute :warehouse_path do |purchase_item|
    warehouse_path(purchase_item.warehouse, selected: purchase_item.id, anchor: purchase_item.id)
  end

  typelize "Array<{ moved_in: string; warehouse_name: string | null }>"
  attribute :warehouse_movements do |purchase_item|
    purchase_item
      .warehouse_movements(warehouses_by_id: params[:warehouses_by_id])
      .sort_by(&:moved_in).reverse.drop(1)
      .map { |movement| {moved_in: format_datetime(movement.moved_in), warehouse_name: movement.warehouse&.name} }
  end

  typelize :string, nullable: true
  attribute :sale_title do |purchase_item|
    purchase_item.sale&.select_title
  end

  typelize :string, nullable: true
  attribute :sale_path do |purchase_item|
    sale_path(purchase_item.sale) if purchase_item.sale
  end

  typelize :string
  attribute :sale_address do |purchase_item|
    purchase_item.sale ? sale_address(purchase_item.sale) : ""
  end

  typelize :string, nullable: true
  attribute :customer_email do |purchase_item|
    purchase_item.sale&.customer&.email
  end

  typelize :string
  attribute :tracking_number do |purchase_item|
    purchase_item.tracking_number.to_s
  end

  attributes :shipping_company_id

  typelize :string
  attribute :shipping_company_name do |purchase_item|
    purchase_item.shipping_company&.name.to_s
  end

  typelize :string
  attribute :shipping_cost do |purchase_item|
    purchase_item.shipping_cost.to_i.to_s
  end

  typelize "Array<PurchasesExpense>"
  attribute :purchase_expenses do |purchase_item|
    expenses = purchase_item.purchase_expenses.sort_by { |expense| [expense.created_at, expense.id] }
    Purchases::ExpenseResource.new(expenses, params: {purchase_item:}).serializable_hash
  end

  typelize({description: :string, amount: :string, create_path: :string})
  attribute :new_purchase_expense do |purchase_item|
    {description: "", amount: "", create_path: purchase_item_expenses_path(purchase_item)}
  end

  def sale_address(sale)
    address = sale.shipping_address

    [
      sale.customer.full_name,
      address&.address_2,
      address&.address_1,
      [address&.postcode, address&.city].compact_blank.join(" ").presence,
      address&.country,
      address&.phone.presence || sale.customer.phone
    ].compact_blank.join("\n")
  end
end
