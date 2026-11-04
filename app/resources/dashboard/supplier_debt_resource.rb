# frozen_string_literal: true

class Dashboard::SupplierDebtResource < ApplicationResource
  typelize :number
  attribute :supplier_id do |supplier_debt|
    supplier_debt.fetch(:supplier).id
  end

  typelize :string, nullable: true
  attribute :supplier_title do |supplier_debt|
    supplier_debt.fetch(:supplier).title
  end

  typelize :string
  attribute :supplier_path do |supplier_debt|
    supplier_path(supplier_debt.fetch(:supplier))
  end

  typelize :string, nullable: true
  attribute :total_cost do |supplier_debt|
    format_money(supplier_debt.fetch(:total_cost))
  end

  typelize :number
  attribute :total_size do |supplier_debt|
    supplier_debt.fetch(:total_size).to_i
  end

  typelize :string, nullable: true
  attribute :paid do |supplier_debt|
    format_money(supplier_debt.fetch(:paid))
  end

  typelize :string, nullable: true
  attribute :total_debt do |supplier_debt|
    format_money(supplier_debt.fetch(:total_debt))
  end
end
