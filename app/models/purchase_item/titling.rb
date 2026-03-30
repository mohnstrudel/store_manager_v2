# frozen_string_literal: true

module PurchaseItem::Titling
  extend ActiveSupport::Concern

  def name
    purchase.full_title
  end

  def title
    "Purchase Item #{id}"
  end
end
