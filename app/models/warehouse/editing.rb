# frozen_string_literal: true

module Warehouse::Editing
  extend ActiveSupport::Concern

  TRANSITIONS_UPDATED = :transitions_updated
  WAREHOUSE_UPDATED = :warehouse_updated

  class_methods do
    def clear_competing_default_warehouses!(except_id: nil)
      # rubocop:disable Rails/SkipsModelValidations
      where(is_default: true)
        .where.not(id: except_id)
        .update_all(is_default: false)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def create_from_form!(attributes, new_media_images:)
    transaction do
      assign_attributes(attributes)
      clear_competing_default_warehouses_if_needed!
      save!
      add_new_media_from_form!(new_media_images)
    end
  end

  def apply_form_changes!(attributes:, transition_ids:, media_attributes:, new_media_images:)
    transaction do
      if transitions_only_update?(attributes)
        sync_transitions!(transition_ids)
        TRANSITIONS_UPDATED
      else
        assign_attributes(attributes)
        clear_competing_default_warehouses_if_needed!
        save!
        update_media_from_form!(media_attributes)
        add_new_media_from_form!(new_media_images)
        sync_transitions!(transition_ids)
        WAREHOUSE_UPDATED
      end
    end
  end

  def update_position!(position)
    update!(position:)
  end

  private

  def transitions_only_update?(attributes)
    attributes.one? { |key, _value| key.to_s == "to_warehouse_ids" }
  end

  def clear_competing_default_warehouses_if_needed!
    return unless is_default?

    self.class.clear_competing_default_warehouses!(except_id: id)
  end
end
