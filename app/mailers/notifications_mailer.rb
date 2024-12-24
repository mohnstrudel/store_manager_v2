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
      subject: "HandsomeCake Goodies. We updated your order, new status: \"#{warehouse_name}\"",
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
    tracking_number: nil,
    tracking_url: nil
  )
    @customer_name = customer_name
    @item_name = item_name
    @new_status = to_warehouse
    @order_number = order_number
    @previous_status = from_warehouse
    @tracking_number = tracking_number
    @tracking_url = tracking_url

    mail(
      subject: "HandsomeCake Goodies. We updated your order, new status: \"#{to_warehouse}\", previous status: \"#{from_warehouse}\"",
      to: email
    ) do |format|
      format.text
    end
  end
end
