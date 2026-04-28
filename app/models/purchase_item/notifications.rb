# frozen_string_literal: true

module PurchaseItem::Notifications
  extend ActiveSupport::Concern

  class_methods do
    def notify_order_status!(purchase_item_ids:)
      return if purchase_item_ids.blank?

      for_notifications.where(id: purchase_item_ids).each do |purchase_item|
        data = notification_data_for(purchase_item)
        next unless data

        NotificationsMailer.order_status_updated_email(
          **data,
          warehouse_name_en: purchase_item.warehouse.external_name_en,
          warehouse_name_de: purchase_item.warehouse.external_name_de,
          warehouse_desc_en: purchase_item.warehouse.desc_en,
          warehouse_desc_de: purchase_item.warehouse.desc_de
        ).deliver_later
      end
    end

    def notify_order_status_change!(purchase_item_ids:, from_id:, to_id:)
      from_id = from_id.to_i
      to_id = to_id.to_i

      return if from_id == to_id
      return if purchase_item_ids.blank?

      transition = WarehouseTransition.active_for_notification(from_id:, to_id:)
      return unless transition

      for_notifications.where(id: purchase_item_ids).each do |purchase_item|
        data = notification_data_for(purchase_item)
        next unless data

        tracking_number = purchase_item.tracking_number.presence || transition.to_warehouse&.container_tracking_number
        tracking_url = purchase_item.shipping_company&.tracking_url.presence || transition.to_warehouse&.courier_tracking_url

        NotificationsMailer.order_status_changed_email(
          **data,
          from_warehouse_name_en: transition.from_warehouse.external_name_en,
          from_warehouse_name_de: transition.from_warehouse.external_name_de,
          to_warehouse_name_en: transition.to_warehouse.external_name_en,
          to_warehouse_name_de: transition.to_warehouse.external_name_de,
          tracking_number:,
          tracking_url:,
          new_status_desc_en: transition.to_warehouse.desc_en,
          new_status_desc_de: transition.to_warehouse.desc_de
        ).deliver_later
      end
    end

    private

    def notification_data_for(purchase_item)
      sale = purchase_item.sale

      return if sale.blank?

      email = sale.customer.email
      return if email.blank?

      {
        email:,
        customer_name: sale.customer.full_name,
        order_number: sale.woo_store_id.presence || sale.shopify_name.presence || sale.id,
        item_name: purchase_item.sale_item.title
      }
    end
  end
end
