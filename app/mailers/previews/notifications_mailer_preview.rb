class NotificationsMailerPreview < ActionMailer::Preview
  def product_purchased_email
    NotificationsMailer.product_purchased_email(
      email: "test@example.com",
      customer_name: "John Doe",
      order_number: "12345",
      warehouse_name: "Warehouse A",
      item_name: "Product A"
    )
  end

  def warehouse_changed_email
    NotificationsMailer.warehouse_changed_email(
      email: "test@example.com",
      customer_name: "John Doe",
      order_number: "12345",
      item_name: "Product A",
      from_warehouse: "Warehouse A",
      to_warehouse: "Warehouse B"
    )
  end
end
