# frozen_string_literal: true

module Purchase::Editing
  extend ActiveSupport::Concern

  def save_editing!
    save!
    move_to_warehouse!(warehouse_id) if warehouse_id.present?
    payments.create!(value: payment_value) if payment_value.present?
  end
end
