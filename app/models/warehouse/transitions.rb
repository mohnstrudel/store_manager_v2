# frozen_string_literal: true

module Warehouse::Transitions
  extend ActiveSupport::Concern

  included do
    has_many :from_transitions, class_name: "WarehouseTransition", foreign_key: :from_warehouse_id, dependent: :destroy, inverse_of: :from_warehouse
    has_many :to_transitions, class_name: "WarehouseTransition", foreign_key: :to_warehouse_id, dependent: :destroy, inverse_of: :to_warehouse
  end

  def sync_transitions(to_warehouse_ids)
    raw_ids = Array(to_warehouse_ids)
    return if raw_ids.blank?

    ids = raw_ids.compact_blank.map(&:to_i).uniq

    from_transitions.where.not(to_warehouse_id: ids).destroy_all

    ids.each do |to_warehouse_id|
      WarehouseTransition.find_or_create_by!(
        from_warehouse: self,
        to_warehouse_id:,
        notification: warehouse_transition_notification
      )
    end
  end

  private

  def warehouse_transition_notification
    @warehouse_transition_notification ||= Notification.find_or_create_by!(
      name: "Warehouse transition",
      event_type: Notification.event_types[:warehouse_changed],
      status: :active
    )
  end
end
