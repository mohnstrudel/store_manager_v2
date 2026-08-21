# frozen_string_literal: true

module VariantAssignment
  extend ActiveSupport::Concern

  included do
    before_validation :normalize_variant_assignment
    validate :validate_variant_assignment
    around_update :reconcile_purchase_item_identity,
      if: :will_save_change_to_variant_identity?
  end

  private

  def reconcile_purchase_item_identity
    PurchaseItem.reconcile_identity_change!(self) { yield }
  end

  def will_save_change_to_variant_identity?
    will_save_change_to_product_id? || will_save_change_to_variant_id?
  end

  def normalize_variant_assignment
    self.product ||= variant.product if product.blank? && variant.present? && new_or_changed_variant_identity?
    return if product.blank? || variant.present?

    self.variant = assignable_base_variant
  end

  def assignable_base_variant
    if product.new_record?
      real_variants = product.association(:variants).target.reject(&:deactivated?).reject(&:base_model?)
      return product.build_base_variant if real_variants.empty?

      return
    end

    product.assignable_variants.base_models.first
  end

  def validate_variant_assignment
    return if product.blank?

    if variant.blank?
      errors.add(:variant, "must be selected")
      return
    end

    if variant.product_id != product_id
      errors.add(:variant, "must belong to the selected Product")
      return
    end

    return unless new_or_changed_variant_identity?
    return if product.assignable_variants.exists?(id: variant_id)

    errors.add(:variant, "is not assignable")
  end

  def new_or_changed_variant_identity?
    new_record? || will_save_change_to_variant_identity?
  end
end
