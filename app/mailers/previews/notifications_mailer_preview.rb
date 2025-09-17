# Preview at http://localhost:3000/rails/mailers/notifications_mailer
class NotificationsMailerPreview < ActionMailer::Preview
  def product_purchased_email
    NotificationsMailer.product_purchased_email(
      email: "test@example.com",
      customer_name: "John Doe",
      order_number: "12345",
      warehouse_name_en: "Processing Center",
      warehouse_name_de: "Verarbeitungszentrum",
      warehouse_desc_en: "Your order is being processed at our main facility",
      warehouse_desc_de: "Ihre Bestellung wird in unserer Hauptanlage bearbeitet",
      item_name: "Product A"
    )
  end

  def warehouse_changed_email
    NotificationsMailer.warehouse_changed_email(
      email: "test@example.com",
      customer_name: "John Doe",
      order_number: "12345",
      item_name: "Product A",
      from_warehouse_name_en: "Processing Center",
      from_warehouse_name_de: "Verarbeitungszentrum",
      to_warehouse_name_en: "Shipping Facility",
      to_warehouse_name_de: "Versandanlage",
      tracking_number: "TRK123456789",
      tracking_url: "https://example.com/tracking/TRK123456789",
      new_status_desc_en: "Your order has been packaged and is ready for shipping",
      new_status_desc_de: "Ihre Bestellung wurde verpackt und ist versandbereit"
    )
  end
end
