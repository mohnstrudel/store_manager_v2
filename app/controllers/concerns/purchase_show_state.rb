# frozen_string_literal: true

module PurchaseShowState
  extend ActiveSupport::Concern

  private

  def prepare_purchase_show_state
    @purchase_items = @purchase
      .purchase_items
      .for_purchase_details
      .order(updated_at: :desc)
    @payments = payments_for_show
    @new_payment ||= @purchase.payments.new(payment_date: Time.zone.today)
  end

  def purchase_show_props
    prepare_purchase_show_state

    {
      purchase: purchase_props(@purchase),
      purchase_items: @purchase_items.map { |purchase_item| purchase_item_props(purchase_item) },
      payments: @payments.map { |payment| payment_props(payment) },
      new_payment: unsaved_payment_props(@new_payment),
      warehouses: Warehouse.order(name: :asc).map { |warehouse| warehouse_props(warehouse) },
      warehouse_move_path: warehouse_move_path
    }
  end

  def payments_for_show
    payments = @purchase.payments.order(payment_date: :asc, created_at: :asc).to_a
    return payments unless inline_payment_errors?

    replace_payment_for_show(payments, @payment)
  end

  def inline_payment_errors?
    defined?(@payment) && @payment&.persisted? && @payment.errors.any?
  end

  def replace_payment_for_show(payments, payment)
    index = payments.index { |existing_payment| existing_payment.id == payment.id }
    return payments unless index

    payments[index] = payment
    payments
  end

  def purchase_props(purchase)
    {
      id: purchase.id,
      path: purchase_path(purchase),
      edit_path: edit_purchase_path(purchase),
      destroy_path: purchase_path(purchase),
      product_path: product_path(purchase.product),
      product_title: purchase.product.full_title.to_s,
      product_image_url: purchase.product.image.to_s.presence,
      product_thumb_url: helpers.thumb_url(purchase.product),
      variant_title: purchase.variant&.title.to_s,
      amount: purchase.amount.to_i,
      item_price: helpers.format_money(purchase.item_price).to_s,
      cost_total: helpers.format_money(purchase.cost_total).to_s,
      shipping_total: helpers.format_money(purchase.shipping_total).to_s,
      paid: helpers.format_money(purchase.paid).to_s,
      debt: helpers.format_money(purchase.debt).to_s,
      supplier_title: purchase.supplier.title.to_s,
      supplier_path: supplier_path(purchase.supplier),
      order_reference: purchase.order_reference.to_s,
      date: helpers.format_date(purchase.date).to_s,
      payment_progress: payment_progress_props(purchase)
    }
  end

  def purchase_item_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      edit_path: edit_purchase_item_path(purchase_item),
      unlink_path: purchase_item_sale_item_link_path(purchase_item),
      warehouse_name: purchase_item.warehouse.name.to_s,
      warehouse_path: warehouse_path(purchase_item.warehouse),
      sale_title: purchase_item.sale&.select_title.to_s,
      sale_path: purchase_item.sale ? sale_path(purchase_item.sale) : nil,
      sale_address: purchase_item.sale ? helpers.sale_address_for_clipboard(purchase_item.sale) : "",
      customer_email: purchase_item.sale&.customer&.email.to_s,
      shipping_cost: helpers.format_money(purchase_item.shipping_cost).to_s
    }
  end

  def payment_props(payment)
    {
      id: payment.id,
      update_path: purchase_payment_path(@purchase, payment),
      destroy_path: purchase_payment_path(@purchase, payment, return_to: purchase_path(@purchase)),
      payment_date: payment.payment_date&.to_date&.iso8601.to_s,
      value: payment.value.to_s,
      errors: payment.errors.full_messages
    }
  end

  def unsaved_payment_props(payment)
    {
      create_path: purchase_payments_path(@purchase),
      payment_date: (payment.payment_date&.to_date || Time.zone.today).iso8601,
      value: payment.value.to_s,
      errors: payment.errors.full_messages
    }
  end

  def payment_progress_props(purchase)
    {
      progress: purchase.progress.to_f,
      paid: helpers.format_money(purchase.item_paid).to_s,
      price: helpers.format_money(purchase.item_price).to_s,
      debt: helpers.format_money(purchase.item_debt).to_s
    }
  end

  def warehouse_props(warehouse)
    {
      id: warehouse.id,
      name: warehouse.name.to_s
    }
  end
end
