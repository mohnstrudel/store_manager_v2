# frozen_string_literal: true

module Warehouse::Lifecycle
  extend ActiveSupport::Concern

  DESTROY_BLOCKED_MESSAGE = "Error. Please select and move out all purchased products before deleting the warehouse"

  def destroy_if_empty!
    if purchase_items.exists?
      errors.add(:base, DESTROY_BLOCKED_MESSAGE)
      raise ActiveRecord::RecordInvalid.new(self)
    end

    destroy!
  end
end
