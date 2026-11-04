# frozen_string_literal: true

class Dashboard::DebtsResource < ApplicationResource
  typelize "Array<DashboardDebt>"
  attribute :debts do |page|
    Dashboard::DebtResource.new(page.fetch(:debts)).serializable_hash
  end

  typelize "Pagination"
  attribute :pagination do |page|
    PaginationResource.for(page.fetch(:debts))
  end

  typelize({q: :string})
  attribute :search do |page|
    {q: page.fetch(:query)}
  end

  typelize "Array<DashboardUnpaidPurchase>"
  attribute :unpaid_purchases do |page|
    Dashboard::UnpaidPurchaseResource.new(page.fetch(:unpaid_purchases)).serializable_hash
  end
end
