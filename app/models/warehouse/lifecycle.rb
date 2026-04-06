# frozen_string_literal: true

module Warehouse::Lifecycle
  extend ActiveSupport::Concern

  def destroy_if_empty!
    if purchase_items.exists?
      errors.add(:base, :destroy_blocked)
      raise ActiveRecord::RecordInvalid.new(self)
    end

    destroy!
  end
end
