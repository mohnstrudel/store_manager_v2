# Preview at http://localhost:3000/rails/mailers/notifications_mailer
class NotificationsMailerPreview < ActionMailer::Preview
  def product_purchased_email
    NotificationsMailer.product_purchased_email(
      email: "test@example.com",
      customer_name: "John Doe",
      order_number: "12345",
      warehouse_name: "Warehouse A",
      warehouse_desc_en: "English description for Warehouse A",
      warehouse_desc_de: "German description for Warehouse A",
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
      to_warehouse: "Warehouse B",
      previous_status_desc_en: "English description for Warehouse A",
      previous_status_desc_de: "German description for Warehouse A",
      new_status_desc_en: "English description for Warehouse B",
      new_status_desc_de: "German description for Warehouse B"
    )
  end
end
