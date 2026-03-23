# frozen_string_literal: true

class Warehouse::UpdateWorkflow
  TRANSITIONS_UPDATED = :transitions_updated
  WAREHOUSE_UPDATED = :warehouse_updated

  def self.call(...)
    new(...).call
  end

  def initialize(warehouse:, attributes:, transition_ids:, after_update: nil)
    @warehouse = warehouse
    @attributes = attributes
    @transition_ids = transition_ids
    @after_update = after_update
  end

  def call
    ActiveRecord::Base.transaction do
      if transitions_only?
        warehouse.sync_transitions!(transition_ids)
        TRANSITIONS_UPDATED
      else
        warehouse.update!(attributes)
        after_update&.call
        Warehouse.ensure_only_one_default(warehouse.id) if warehouse.is_default?
        warehouse.sync_transitions!(transition_ids)
        WAREHOUSE_UPDATED
      end
    end
  end

  private

  attr_reader :warehouse, :attributes, :transition_ids, :after_update

  def transitions_only?
    attributes.one? { |key, _value| key.to_s == "to_warehouse_ids" }
  end
end
