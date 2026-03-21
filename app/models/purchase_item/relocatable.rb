# frozen_string_literal: true

module PurchaseItem::Relocatable
  extend ActiveSupport::Concern

  def relocate_to!(destination_id)
    update!(warehouse_id: destination_id)
  end
end
