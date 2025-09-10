class PurchasedNotifier
  def self.handle_product_purchase(**kwargs)
    new(**kwargs).handle_product_purchase
  end

  def self.handle_warehouse_change(**kwargs)
    new(**kwargs).handle_warehouse_change
  end

  def initialize(
    purchase_item_ids:,
    from_id: nil,
    to_id: nil
  )
    @purchase_item_ids = purchase_item_ids
    @from_id = from_id.to_i
    @to_id = to_id.to_i
  end

  def handle_product_purchase
    return if @purchase_item_ids.blank?

    dispatch_product_purchased_message
  end

  def handle_warehouse_change
    return warn_about(:same_destination) if @from_id == @to_id
    return if @purchase_item_ids.blank?

    dispatch_warehouse_changed_message
  end

  private

  def format_warehouse_name(warehouse)
    warehouse.external_name.presence || warehouse.name
  end

  def extract_common_data(purchase_item)
    sale = purchase_item.sale

    if sale.blank?
      {}
    else
      {
        email: sale.customer.email,
        customer_name: sale.customer.full_name,
        order_number: sale.woo_id.presence || sale.shopify_name.presence || sale.id,
        item_name: purchase_item.sale_item.title
      }
    end
  end

  def dispatch_product_purchased_message
    purchase_items = PurchaseItem
      .with_notification_details
      .includes(:warehouse)
      .where(id: @purchase_item_ids)

    purchase_items.each do |purchase_item|
      if purchase_item&.sale.blank?
        warn_about(:no_sale, purchase_item.id)
        next
      end

      data = extract_common_data(purchase_item)

      if data[:email].blank?
        warn_about(:no_email, purchase_item.id)
        next
      end

      NotificationsMailer.product_purchased_email(
        **data,
        warehouse_name: format_warehouse_name(purchase_item.warehouse),
        warehouse_desc_en: purchase_item.warehouse.desc_en,
        warehouse_desc_de: purchase_item.warehouse.desc_de
      ).deliver_later
    end
  end

  def dispatch_warehouse_changed_message
    transition = WarehouseTransition
      .includes(:notification, :from_warehouse, :to_warehouse)
      .find_by(
        from_warehouse_id: @from_id,
        to_warehouse_id: @to_id
      )

    unless transition&.notification&.active?
      return warn_about(:no_transitions)
    end

    purchase_items = PurchaseItem
      .with_notification_details
      .where(id: @purchase_item_ids)

    purchase_items.each do |purchase_item|
      data = extract_common_data(purchase_item)

      if data[:email].blank?
        warn_about(:no_email, purchase_item.id)
        next
      end

      NotificationsMailer.warehouse_changed_email(
        **data,
        from_warehouse: format_warehouse_name(transition.from_warehouse),
        to_warehouse: format_warehouse_name(transition.to_warehouse),
        tracking_number: transition.to_warehouse&.container_tracking_number,
        tracking_url: transition.to_warehouse&.courier_tracking_url,
        previous_status_desc_en: transition.from_warehouse.desc_en,
        previous_status_desc_de: transition.from_warehouse.desc_de,
        new_status_desc_en: transition.to_warehouse.desc_en,
        new_status_desc_de: transition.to_warehouse.desc_de
      ).deliver_later
    end
  end

  def warn_about(subj, id = nil)
    prefix = "  ↳ Skipping notifications. %s"
    case subj
    when :same_destination
      warn prefix % "Destination is the same as the original location"
    when :no_transitions
      warn prefix % "No active transitions found for warehouses: #{@from_id} -> #{@to_id}"
    when :no_sale
      warn prefix % "Missing sale for purchased product ID: #{id}"
    when :no_email
      warn prefix % "Missing email for purchased product ID: #{id}"
    end
  end
end
