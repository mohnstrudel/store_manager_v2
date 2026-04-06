# frozen_string_literal: true

module Warehouse::Editing
  extend ActiveSupport::Concern

  TRANSITIONS_UPDATED = :transitions_updated
  WAREHOUSE_UPDATED = :warehouse_updated

  def create_from_form!(attributes, new_media_images:)
    transaction do
      assign_attributes(attributes)
      validate_default_warehouse_choice!
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
        validate_default_warehouse_choice!
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

  def blocking_default_warehouse
    @blocking_default_warehouse ||= find_blocking_default_warehouse
  end

  private

  def transitions_only_update?(attributes)
    attributes.one? { |key, _value| key.to_s == "to_warehouse_ids" }
  end

  def validate_default_warehouse_choice!
    return unless blocking_default_warehouse

    errors.add(:is_default, :conflict)
    raise ActiveRecord::RecordInvalid, self
  end

  def find_blocking_default_warehouse
    return unless is_default?

    self.class.where(is_default: true).where.not(id: id).first
  end
end
