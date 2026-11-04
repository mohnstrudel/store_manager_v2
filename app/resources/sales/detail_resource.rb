# frozen_string_literal: true

class Sales::DetailResource < Sales::BaseResource
  PROFITABILITY_AMOUNTS = %i[
    gross_revenue item_price_total purchase_expenses purchase_shipping_cost direct_expenses
    business_expenses net_profit collected_revenue purchase_paid cash_position
  ].freeze

  typelize :string
  attribute :edit_path do |sale|
    edit_sale_path(sale)
  end

  typelize :boolean
  attribute :can_link_purchase_items do |sale|
    (sale.active? || sale.completed?) && sale.unlinked_sale_items?
  end

  typelize :string
  attribute :link_purchase_items_path do |sale|
    sale_purchase_item_link_path(sale)
  end

  typelize :string
  attribute :pull_path do |sale|
    sale_pull_path(sale)
  end

  typelize :string
  attribute :shop_admin_url do |sale|
    sale_shop_link(sale)
  end

  one :customer, resource: SaleCustomerResource

  attributes :note

  typelize({
    scope: '"plan" | "sale"',
    gross_revenue: "string | null",
    item_price_total: "string | null",
    purchase_expenses: "string | null",
    purchase_shipping_cost: "string | null",
    direct_expenses: "string | null",
    business_expenses: "string | null",
    net_profit: "string | null",
    collected_revenue: "string | null",
    purchase_paid: "string | null",
    cash_position: "string | null"
  }, nullable: true)
  attribute :profitability do |sale|
    profitability(sale) if can_view_profitability? && !sale.follow_up_payment?
  end

  typelize "Array<WarehouseOption>"
  attribute :warehouses do |_sale|
    WarehouseOptionResource.new(Warehouse.order(name: :asc)).serializable_hash
  end

  typelize :string
  attribute :warehouse_move_path do |_sale|
    warehouse_move_path
  end

  typelize "Array<SalesDetailItem>"
  attribute :sale_items do |sale|
    if sale.follow_up_payment?
      []
    else
      Sales::DetailItemResource.new(
        sale.sale_items,
        params: {
          shipping_shares: sale.shipping_shares_by_item_id,
          origin_price: sale.projected_item_price,
          can_view_profitability: can_view_profitability?,
          expense_fraction:
        }
      ).serializable_hash
    end
  end

  typelize "SaleAddress", nullable: true
  one :shipping_address, resource: SaleAddressResource, if: proc { |sale| !sale.follow_up_payment? }

  typelize "SaleAddress", nullable: true
  one :billing_address, resource: SaleAddressResource, if: proc { |sale| !sale.follow_up_payment? }

  typelize :boolean
  attribute :billing_differs_from_shipping, if: proc { |sale| !sale.follow_up_payment? } do |sale|
    sale.billing_differs_from_shipping?
  end

  typelize :string, nullable: true
  attribute :discount_total, if: proc { |sale| !sale.follow_up_payment? } do |sale|
    format_money(sale.discount_total)
  end

  typelize :string, nullable: true
  attribute :shipping_total, if: proc { |sale| !sale.follow_up_payment? } do |sale|
    format_money(sale.shipping_total)
  end

  def profitability(sale)
    summary = sale.profitability_summary(expense_fraction:)
    return if summary.nil?

    {scope: summary[:scope], **PROFITABILITY_AMOUNTS.index_with { |amount| format_money(summary[amount]) }}
  end

  def expense_fraction
    @expense_fraction ||= can_view_profitability? ? ExpenseRate.combined_fraction : 0
  end

  def can_view_profitability?
    params[:can_view_profitability] == true
  end
end
