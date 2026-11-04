# frozen_string_literal: true

module Helpers
  module PurchaseItemScenarios
    def ledger_for(purchase_item)
      OutboundEmail.where(purchase_item_id: purchase_item.id).order(:id)
    end
  end
end
