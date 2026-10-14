# frozen_string_literal: true

module PurchaseItem::Notifications
  extend ActiveSupport::Concern

  class_methods do
    def notify_order_status!(purchase_item_ids:)
      return if purchase_item_ids.blank?

      each_locked_for_notifications(purchase_item_ids) do |purchase_item|
        data = notification_data_for(purchase_item)
        next unless data

        record_outbound_email!(
          purchase_item,
          source: :explicit_resend,
          mail_kind: :order_status_updated,
          data:,
          mail: order_status_updated_mail(purchase_item, data)
        )
      end
    end

    def record_status_change_notifications!(purchase_item_ids:, from_id:, to_id:)
      from_id = from_id.to_i
      to_id = to_id.to_i

      return if from_id == to_id
      return if purchase_item_ids.blank?

      transition = WarehouseTransition.active_for_notification(from_id:, to_id:)
      return unless transition

      each_locked_for_notifications(purchase_item_ids) do |purchase_item|
        data = notification_data_for(purchase_item)
        next unless data

        record_outbound_email!(
          purchase_item,
          source: :warehouse_move,
          mail_kind: :order_status_changed,
          data:,
          mail: order_status_changed_mail(purchase_item, transition, data)
        )
      end
    end

    def record_link_notifications!(purchase_item_ids:)
      return if purchase_item_ids.blank?

      each_locked_for_notifications(purchase_item_ids) do |purchase_item|
        next if latest_outbound_pair?(purchase_item)

        data = notification_data_for(purchase_item)
        next unless data

        record_outbound_email!(
          purchase_item,
          source: :link,
          mail_kind: :order_status_updated,
          data:,
          mail: order_status_updated_mail(purchase_item, data)
        )
      end
    end

    private

    def each_locked_for_notifications(purchase_item_ids, &)
      transaction do
        for_notifications.where(id: purchase_item_ids).order(:id).lock.each(&)
      end
    end

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

    def record_outbound_email!(purchase_item, source:, mail_kind:, data:, mail:)
      message = mail.message

      OutboundEmail.create!(
        source:,
        mail_kind:,
        purchase_item_id: purchase_item.id,
        sale_item_id: purchase_item.sale_item_id,
        customer_id: purchase_item.sale.customer_id,
        warehouse_id: purchase_item.warehouse_id,
        recipient: message.to.first,
        recipient_name: data.fetch(:customer_name),
        product_title: data.fetch(:item_name),
        sender: message[:from].to_s,
        subject: message.subject,
        body: message.body.decoded
      )
    end

    def order_status_updated_mail(purchase_item, data)
      NotificationsMailer.order_status_updated_email(
        **data,
        warehouse_name_en: purchase_item.warehouse.external_name_en,
        warehouse_name_de: purchase_item.warehouse.external_name_de,
        warehouse_desc_en: purchase_item.warehouse.desc_en,
        warehouse_desc_de: purchase_item.warehouse.desc_de
      )
    end

    def order_status_changed_mail(purchase_item, transition, data)
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
      )
    end

    def latest_outbound_pair?(purchase_item)
      OutboundEmail
        .where(purchase_item_id: purchase_item.id)
        .order(id: :desc)
        .pick(:sale_item_id, :warehouse_id) == [purchase_item.sale_item_id, purchase_item.warehouse_id]
    end
  end
end
