# frozen_string_literal: true

class PurchaseItems::NewResource < PurchaseItems::FormPageResource
  typelize :string
  attribute :form_action do |page|
    warehouse_items_path(page.fetch(:warehouse))
  end

  typelize :string
  attribute :cancel_path do |page|
    warehouse_path(page.fetch(:warehouse))
  end
end
