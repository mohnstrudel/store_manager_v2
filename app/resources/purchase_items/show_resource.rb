# frozen_string_literal: true

class PurchaseItems::ShowResource < ApplicationResource
  typelize "PurchaseItemsDetail"
  attribute :purchase_item do |page|
    PurchaseItems::DetailResource.new(page.fetch(:purchase_item)).serializable_hash
  end
end
