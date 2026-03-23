# frozen_string_literal: true

module WarehouseTransition::Lookup
  extend ActiveSupport::Concern

  included do
    scope :for_notification_lookup, -> {
      includes(:notification, :from_warehouse, :to_warehouse)
    }

    scope :with_active_notification, -> {
      joins(:notification).merge(Notification.active)
    }
  end

  class_methods do
    def active_for_notification(from_id:, to_id:)
      for_notification_lookup
        .with_active_notification
        .find_by(from_warehouse_id: from_id, to_warehouse_id: to_id)
    end
  end
end
