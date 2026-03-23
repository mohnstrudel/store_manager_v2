# frozen_string_literal: true

module Warehouse::Financials
  extend ActiveSupport::Concern

  def average_payment_progress
    return 0 if purchases.none?

    progresses = purchases.map(&:progress)
    (progresses.sum / progresses.size).round
  end

  def total_debt
    purchases.sum(&:debt).round
  end
end
