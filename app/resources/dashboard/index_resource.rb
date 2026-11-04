# frozen_string_literal: true

class Dashboard::IndexResource < ApplicationResource
  typelize :boolean
  attribute :sales_hook_disabled do |_page|
    Config.sales_hook_disabled?
  end

  typelize :string
  attribute :last_orders_pull_path do |_page|
    last_orders_pull_path
  end

  typelize({rows: "Array<DashboardSaleDebt>", count: :number})
  attribute :sale_debts, inertia: {defer: {group: "sale_debts"}} do |page|
    debts = page.fetch(:sale_debts)
    {rows: Dashboard::SaleDebtResource.new(debts.first(5)).serializable_hash, count: debts.length}
  end

  typelize({rows: "Array<DashboardSupplierDebt>", total: "string | null"})
  attribute :supplier_debts, inertia: {defer: {group: "supplier_debts"}} do |page|
    debts = page.fetch(:suppliers).debt_summaries.reject { |supplier_debt| supplier_debt[:total_debt].zero? }
    {
      rows: Dashboard::SupplierDebtResource.new(debts).serializable_hash,
      total: format_money(debts.sum { |supplier_debt| supplier_debt[:total_debt] })
    }
  end

  typelize :string
  attribute :debts_path do |_page|
    debts_path
  end
end
