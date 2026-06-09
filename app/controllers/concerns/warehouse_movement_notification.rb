# frozen_string_literal: true

module WarehouseMovementNotification
  extend ActiveSupport::Concern

  private

  def flash_movement_notice(moved_count, destination_warehouse)
    return unless moved_count.positive?

    products = "product".pluralize(moved_count)
    flash[:notice] = {
      message: "Success! #{moved_count} purchased #{products} moved to:",
      link: {
        label: destination_warehouse.name,
        href: warehouse_path(destination_warehouse)
      }
    }
  end
end
