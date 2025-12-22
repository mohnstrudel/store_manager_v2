# frozen_string_literal: true
module WarehouseMovementNotification
  extend ActiveSupport::Concern
  include ActionView::Helpers::OutputSafetyHelper

  private

  def flash_movement_notice(moved_count, destination_warehouse)
    return unless moved_count.positive?

    destination_link = view_context.link_to(
      destination_warehouse.name,
      warehouse_path(destination_warehouse),
      class: "link"
    )
    products = "product".pluralize(moved_count)

    flash[:notice] = safe_join([
      "Success! #{moved_count} purchased #{products} moved to: ",
      destination_link
    ])
  end
end
