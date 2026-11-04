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

    render_inertia "OutboundEmails/Index", serializer: OutboundEmails::IndexResource,
      locals: {outbound_emails: @outbound_emails, sale_items:, purchase_items:, customer_ids:, query:}
  end

  def show
    @outbound_email = OutboundEmail.where.not(source: :baseline).find(params.expect(:id))
    sale_item = SaleItem.includes(product: {media: {image_attachment: :blob}}).find_by(id: @outbound_email.sale_item_id)

    render_inertia "OutboundEmails/Show", serializer: OutboundEmails::ShowResource,
      locals: {outbound_email: @outbound_email, sale_item:}
  end
end
