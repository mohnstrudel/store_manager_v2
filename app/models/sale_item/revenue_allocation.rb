# frozen_string_literal: true

module SaleItem::RevenueAllocation
  extend ActiveSupport::Concern

  def apply_revenue_allocation(amounts)
    assign_attributes(amounts)
    save!(validate: false)
  end
end
