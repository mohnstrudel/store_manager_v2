# frozen_string_literal: true

module Purchase::Creation
  extend ActiveSupport::Concern

  def create_from_form!(attributes:, initial_warehouse_id:, initial_payment_value:)
    transaction do
      assign_attributes(attributes)
      save!
      move_to_warehouse!(initial_warehouse_id) if initial_warehouse_id.present?
      payments.create!(value: initial_payment_value) if initial_payment_value.present?
    end
  end
end
