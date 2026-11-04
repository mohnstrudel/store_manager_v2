# frozen_string_literal: true

module Purchase::Placement
  extend ActiveSupport::Concern

  def place!(attributes: {}, warehouse_id: self.warehouse_id, payment_value: self.payment_value)
    transaction do
      assign_attributes(attributes)
      save!
      move_to_warehouse!(warehouse_id) if warehouse_id.present?
      record_payment!(payment_value) if payment_value.present?
    end
  end
end
