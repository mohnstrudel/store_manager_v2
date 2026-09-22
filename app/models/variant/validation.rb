# frozen_string_literal: true

module Variant::Validation
  extend ActiveSupport::Concern

  included do
    attr_accessor :_destroy

    validates :sku, presence: true, unless: :should_be_removed?
    validate :validate_base_model_identity
  end

  def should_be_removed?
    ActiveModel::Type::Boolean.new.cast(@_destroy)
  end

  private

  def validate_base_model_identity
    return if product&.synchronizing_variant_availability?

    validate_base_model_is_immutable
    validate_base_model_is_unique
  end

  def validate_base_model_is_immutable
    persisted_as_base = persisted? &&
      size_id_in_database.nil? &&
      version_id_in_database.nil? &&
      color_id_in_database.nil?
    return unless persisted_as_base
    return unless will_save_change_to_deactivated_at? ||
      will_save_change_to_size_id? ||
      will_save_change_to_version_id? ||
      will_save_change_to_color_id?

    errors.add(:base, "Base Model lifecycle is owned by Product")
  end

  def validate_base_model_is_unique
    return unless base_model?
    return if product.blank?

    in_memory_duplicate = product.association(:variants).target.any? { |candidate|
      candidate != self &&
        !candidate.should_be_removed? &&
        candidate.base_model?
    }
    persisted_duplicate = product.variants.base_models.where.not(id: id).exists?
    return unless in_memory_duplicate || persisted_duplicate

    errors.add(:base, "Base Model already exists")
  end
end
