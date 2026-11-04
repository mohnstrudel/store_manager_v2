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

  typelize "Array<DashboardSaleDebt>"
  attribute :sale_debts do |page|
    Dashboard::SaleDebtResource.new(page.fetch(:sale_debts).first(5)).serializable_hash
  end

  typelize :number
  attribute :sale_debts_count do |page|
    page.fetch(:sale_debts).length
  end

  typelize "Array<DashboardSupplierDebt>"
  attribute :suppliers_debts do |page|
    debts = page.fetch(:suppliers_debts).reject { |supplier_debt| supplier_debt[:total_debt].zero? }
    Dashboard::SupplierDebtResource.new(debts).serializable_hash
  end

  typelize :string, nullable: true
  attribute :total_suppliers_debt do |page|
    format_money(page.fetch(:suppliers_debts).sum { |supplier_debt| supplier_debt[:total_debt] })
  end

  typelize :string
  attribute :debts_path do |_page|
    debts_path
  end
end
