# frozen_string_literal: true

module Warehouse::Editing
  extend ActiveSupport::Concern

  TRANSITIONS_UPDATED = :transitions_updated
  WAREHOUSE_UPDATED = :warehouse_updated

  class_methods do
    def ensure_only_one_default(id)
      # rubocop:disable Rails/SkipsModelValidations
      where(is_default: true)
        .where.not(id:)
        .update_all(is_default: false)
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def create_from_form!(attributes)
    transaction do
      assign_attributes(attributes)
      self.class.ensure_only_one_default(nil) if is_default?
      save!
      yield self if block_given?
      self.class.ensure_only_one_default(id) if is_default?
    end
  end

  def apply_form_changes!(attributes:, transition_ids:)
    transaction do
      if transitions_only_update?(attributes)
        sync_transitions!(transition_ids)
        TRANSITIONS_UPDATED
      else
        update!(attributes)
        yield self if block_given?
        self.class.ensure_only_one_default(id) if is_default?
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
end
