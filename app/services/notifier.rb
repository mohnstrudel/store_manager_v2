class Notifier
  def initialize(
    purchased_product_ids:,
    from_id: nil,
    to_id: nil
  )
    @purchased_product_ids = purchased_product_ids
    @from_id = from_id.to_i
    @to_id = to_id.to_i
  end

  def warn_about(subj, id = nil)
    prefix = "  ↳ Skipping notifications. %s"
    case subj
    when :same_destination
      warn prefix % "Destination is the same as the original location"
    when :no_payload
      warn prefix % "Missing purchased products"
    when :no_transitions
      warn prefix % "No active transitions found for warehouses: #{@from_id} -> #{@to_id}"
    when :no_sale
      warn prefix % "Missing sale for purchased product ID: #{id}"
    when :no_email
      warn prefix % "Missing email for purchased product ID: #{id}"
    end
  end

  def handle_product_purchase
    return warn_about(:no_payload) if @purchased_product_ids.blank?

    dispatch_product_purchased_message
  end

  def handle_warehouse_change
    return warn_about(:same_destination) if @from_id == @to_id
    return warn_about(:no_payload) if @purchased_product_ids.blank?

    dispatch_warehouse_changed_message
  end

  private

  def format_warehouse_name(warehouse)
    warehouse.external_name.presence || warehouse.name
  end

  def extract_common_data(purchased_product)
    return {} if purchased_product.sale.blank?

    {
      email: purchased_product.sale.customer.email,
      customer_name: purchased_product.sale.customer.full_name,
      order_number: purchased_product.sale.woo_id || purchased_product.sale.id,
      item_name: purchased_product.product_sale.title
    }
  end

  def dispatch_product_purchased_message
    purchased_products = PurchasedProduct
      .with_notification_details
      .includes(:warehouse)
      .where(id: @purchased_product_ids)

    purchased_products.each do |purchased_product|
      if purchased_product&.sale.blank?
        warn_about(:no_sale, purchased_product.id)
        next
      end

      data = extract_common_data(purchased_product)
      if data[:email].blank?
        warn_about(:no_email, purchased_product.id)
        next
      end

      NotificationsMailer.product_purchased_email(
        **data,
        warehouse_name: format_warehouse_name(purchased_product.warehouse)
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

    purchased_products = PurchasedProduct
      .with_notification_details
      .where(id: @purchased_product_ids)

    purchased_products.each do |purchased_product|
      data = extract_common_data(purchased_product)

      if data[:email].blank?
        warn_about(:no_email, purchased_product.id)
        next
      end

      NotificationsMailer.warehouse_changed_email(
        **data,
        from_warehouse: format_warehouse_name(transition.from_warehouse),
        to_warehouse: format_warehouse_name(transition.to_warehouse),
        tracking_number: purchased_product.tracking_number,
        tracking_url: purchased_product&.shipping_company&.tracking_url
      ).deliver_later
    end
  end
end
