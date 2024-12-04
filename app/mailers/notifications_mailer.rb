class NotificationsMailer < ApplicationMailer
  def product_purchased_email(
    customer_name:,
    email:,
    item_name:,
    order_number:,
    warehouse_name:
  )
    @customer_name = customer_name
    @item_name = item_name
    @order_number = order_number
    @warehouse_name = warehouse_name

    mail(
      subject: "We relocated your order to \"#{warehouse_name}\"",
      to: email
    ) do |format|
      format.text
    end
  end

  def warehouse_changed_email(
    customer_name:,
    email:,
    from_warehouse:,
    item_name:,
    order_number:,
    to_warehouse:,
    tracking_number:,
    tracking_url:
  )
    @customer_name = customer_name
    @item_name = item_name
    @new_status = to_warehouse
    @order_number = order_number
    @previous_status = from_warehouse
    @tracking_number = tracking_number
    @tracking_url = tracking_url

    mail(
      subject: "We relocated your order from \"#{from_warehouse}\" to \"#{to_warehouse}\"",
      to: email
    ) do |format|
      format.text
    end
  end
end
