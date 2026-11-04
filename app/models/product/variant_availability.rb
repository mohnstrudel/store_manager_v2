# frozen_string_literal: true

module Product::VariantAvailability
  extend ActiveSupport::Concern

  included do
    validate :validate_one_base_variant
  end

  def variant_repair_candidates
    assignable_variants.or(variants.deactivated.real)
  end

  def assignable_variants
    active_real_variants = variants.active.real
    return active_real_variants if active_real_variants.exists?

    variants.active.base_models
  end

  def assignable_variants_with_options
    return assignable_among(variants.reject(&:deactivated?)) if variants.loaded?

    assignable_variants.includes(:color, :size, :version).to_a
  end

  def synchronize_variant_availability
    transaction do
      with_variant_availability_lock { synchronize_variant_availability_under_lock }
    end
  end

  def with_variant_availability_lock
    self.class.where(id:).lock.pick(:id)
    yield
  end

  def synchronizing_variant_availability?
    @synchronizing_variant_availability == true
  end

  private

  def assignable_among(active_variants)
    active_variants.reject(&:base_model?).presence || active_variants.select(&:base_model?)
  end

  def synchronize_variant_availability_under_lock
    return if association(:variants).target.any? { |variant| variant.base_model? && variant.new_record? }

    base = variants.base_models.first!
    should_deactivate_base = variants.active.real.exists?
    return if base.deactivated? == should_deactivate_base

    @synchronizing_variant_availability = true
    base.association(:product).target = self
    should_deactivate_base ? base.deactivate : base.reactivate
  ensure
    @synchronizing_variant_availability = false
  end

  def validate_one_base_variant
    base_variants = association(:variants).target.reject(&:should_be_removed?).select(&:base_model?)
    removed_base_ids = association(:variants).target
      .select(&:should_be_removed?)
      .select(&:base_model?)
      .filter_map(&:id)
    persisted_base_ids = variants.base_models.where.not(id: removed_base_ids).ids
    base_ids = (base_variants.filter_map(&:id) + persisted_base_ids).uniq
    new_base_count = base_variants.count(&:new_record?)

    return if base_ids.one? && new_base_count.zero?
    return if base_ids.empty? && new_base_count == 1

    errors.add(:variants, "must contain exactly one Base Model")
  end
end
