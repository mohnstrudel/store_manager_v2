# frozen_string_literal: true

class OutboundEmailsController < ApplicationController
  def index
    @outbound_emails = OutboundEmail.where.not(source: :baseline).order(id: :desc)
    query = params[:q].to_s.strip.first(200)
    @outbound_emails = @outbound_emails.search(query) if query.present?
    @outbound_emails = @outbound_emails.select(:id, :recipient, :recipient_name, :product_title, :subject, :state, :created_at, :accepted_at, :sale_item_id, :purchase_item_id, :customer_id).page(params[:page]).per(25)
    sale_items = SaleItem.includes(sale: :woo_info, product: {media: {image_attachment: :blob}})
      .where(id: @outbound_emails.map(&:sale_item_id)).index_by(&:id)
    purchase_items = PurchaseItem.includes(:purchase)
      .where(id: @outbound_emails.map(&:purchase_item_id)).index_by(&:id)
    customer_ids = Customer.where(id: @outbound_emails.map(&:customer_id)).pluck(:id)

    render inertia: "OutboundEmails/Index", props: {
      outbound_emails: @outbound_emails.map do |email|
        sale_item = sale_items[email.sale_item_id]
        sale = sale_item&.sale
        purchase = purchase_items[email.purchase_item_id]&.purchase

        {
          id: email.id,
          recipient: email.recipient,
          recipient_name: email.recipient_name,
          customer_path: customer_ids.include?(email.customer_id) ? customer_path(email.customer_id) : nil,
          subject: email.subject,
          product_title: email.product_title,
          product_thumb_url: sale_item && helpers.thumb_url(sale_item.product),
          sale_path: sale && sale_path(sale),
          sale_label: sale && "Sale #{sale.shop_identifier.presence || sale.id}",
          purchase_path: purchase && purchase_path(purchase),
          purchase_label: purchase && "Purchase #{purchase.id}",
          state: email.state,
          created_at: email.created_at,
          accepted_at: email.accepted_at,
          path: outbound_email_path(email)
        }
      end,
      pagination: helpers.pagination_props(@outbound_emails),
      search: {q: query}
    }
  end

  def show
    @outbound_email = OutboundEmail.where.not(source: :baseline).find(params.expect(:id))
    sale_item = SaleItem.includes(product: {media: {image_attachment: :blob}}).find_by(id: @outbound_email.sale_item_id)

    render inertia: "OutboundEmails/Show", props: {
      outbound_email: @outbound_email.as_json(only: %i[
        id recipient recipient_name sender subject body product_title state attempts
        last_attempt_at last_error accepted_at created_at
      ]).merge(product_thumb_url: sale_item && helpers.thumb_url(sale_item.product))
    }
  end
end
