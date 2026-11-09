# frozen_string_literal: true

module Product::InitialPurchase
  extend ActiveSupport::Concern

  included do
    attr_accessor :initial_purchase
  end

  def draft_initial_purchase(purchase_attributes)
    self.initial_purchase = (Purchase.new(purchase_attributes) if new_record? && purchase_attributes.present?)
  end

  def validate_initial_purchase
    return if initial_purchase.blank?

    initial_purchase.valid?
    relevant_errors = initial_purchase.errors.reject { |e|
      e.attribute == :product_id ||
        (e.attribute == :base && e.message == "must have a product or variant")
    }
    add_initial_purchase_errors(relevant_errors)
    errors.add(:initial_purchase, :invalid) if relevant_errors.any?
  end

  def place_initial_purchase(draft_variants:, variant_client_key:)
    return unless initial_purchase

    variant = draft_variants[variant_client_key]
    unless variant_client_key.present? && variant&.persisted? && !variant.should_be_removed?
      message = variant_client_key.present? ? "is invalid" : "must be selected"
      initial_purchase.errors.add(:variant_client_key, message)
      errors.add("purchase.0.variant_client_key", message)
      errors.add(:initial_purchase, :invalid)
      raise ActiveRecord::RecordInvalid.new(self)
    end

    initial_purchase.product = self
    initial_purchase.variant = variant
    initial_purchase.place
  rescue ActiveRecord::RecordInvalid => error
    raise if error.record.equal?(self)

    add_initial_purchase_errors(error.record.errors)
    errors.add(:initial_purchase, :invalid)
    raise ActiveRecord::RecordInvalid.new(self)
  end

  private

  def add_initial_purchase_errors(purchase_errors)
    purchase_errors.each do |error|
      nested_attribute = (error.attribute == :base) ? "base" : error.attribute
      errors.add("purchase.0.#{nested_attribute}", error.message)
    end
  end
end
