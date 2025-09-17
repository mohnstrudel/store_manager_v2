class NotificationsMailer < ApplicationMailer
  def product_purchased_email(
    customer_name:,
    email:,
    item_name:,
    order_number:,
    warehouse_name_en:,
    warehouse_name_de:,
    warehouse_desc_en: nil,
    warehouse_desc_de: nil
  )
    @customer_name = customer_name
    @item_name = item_name
    @order_number = order_number
    @warehouse_name_en = warehouse_name_en
    @warehouse_name_de = warehouse_name_de
    @warehouse_desc_en = warehouse_desc_en
    @warehouse_desc_de = warehouse_desc_de

    mail(
      subject: "HandsomeCake Goodies. We updated your order, new status: \"#{warehouse_name_en}\"",
      to: email
    ) do |format|
      format.text
    end
  end

  def warehouse_changed_email(
    customer_name:,
    email:,
    item_name:,
    order_number:,
    from_warehouse_name_en:,
    from_warehouse_name_de:,
    to_warehouse_name_en:,
    to_warehouse_name_de:,
    tracking_number: nil,
    tracking_url: nil,
    new_status_desc_en: nil,
    new_status_desc_de: nil
  )
    @customer_name = customer_name
    @item_name = item_name
    @order_number = order_number
    @from_warehouse_name_en = from_warehouse_name_en
    @from_warehouse_name_de = from_warehouse_name_de
    @to_warehouse_name_en = to_warehouse_name_en
    @to_warehouse_name_de = to_warehouse_name_de
    @tracking_number = tracking_number
    @tracking_url = tracking_url
    @new_status_desc_en = new_status_desc_en
    @new_status_desc_de = new_status_desc_de

    mail(
      subject: "HandsomeCake Goodies. We updated your order, new status: \"#{to_warehouse_name_en}\", previous status: \"#{from_warehouse_name_en}\"",
      to: email
    ) do |format|
      format.text
    end
  end
end
