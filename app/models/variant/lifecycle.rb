# frozen_string_literal: true

module Variant::Lifecycle
  extend ActiveSupport::Concern

  included do
    around_save :synchronize_product_variant_availability
    around_destroy :synchronize_product_variant_availability
    before_destroy :prevent_referenced_assignment_removal
    before_destroy :prevent_direct_base_model_removal
  end

  def remove_or_deactivate!
    if has_sales_or_purchases?
      update!(deactivated_at: Time.current)
    else
      destroy!
    end
  end

  private

  def synchronize_product_variant_availability
    return yield if product_owned_destruction? || product.synchronizing_variant_availability?
    return yield unless product.persisted?

    product.with_variant_availability_lock do
      if base_model_identity_conflict?
        errors.add(:base, "Base Model already exists")
        throw(:abort)
      end

      result = yield
      product.send(:synchronize_variant_availability_under_lock!) if result
      result
    end
  end

  def prevent_direct_base_model_removal
    return unless base_model?
    return if product_owned_destruction?

    errors.add(:base, "Base Model lifecycle is owned by Product")
    throw(:abort)
  end

  def prevent_referenced_assignment_removal
    return if product_owned_destruction?

    association = :sale_items if sale_items.exists?
    association ||= :purchases if purchases.exists?
    return unless association

    raise ActiveRecord::DeleteRestrictionError.new(association)
  end

  def base_model_identity_conflict?
    base_model? && product.variants.base_models.where.not(id: id).exists?
  end

  def product_owned_destruction?
    destroyed_by_association == Product.reflect_on_association(:variants)
  end
end
