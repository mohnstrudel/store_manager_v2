module WarehouseMovementNotification
  extend ActiveSupport::Concern

  private

  def flash_movement_notice(moved_count, destination_warehouse)
    return unless moved_count.positive?

    destination_link = view_context.link_to(
      destination_warehouse.name,
      warehouse_path(destination_warehouse)
    )
    products = "product".pluralize(moved_count)

    flash[:notice] = "Success! #{moved_count} purchased #{products} moved to: #{destination_link}".html_safe
  end
end
