# frozen_string_literal: true

module Warehouse::Lifecycle
  extend ActiveSupport::Concern

  def destroy_if_empty
    if empty?
      destroy!
    else
      errors.add(:base, :destroy_blocked)
      raise ActiveRecord::RecordInvalid.new(self)
    end
  end

  def empty?
    !purchase_items.exists?
  end
end
