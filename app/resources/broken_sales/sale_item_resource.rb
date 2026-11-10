# frozen_string_literal: true

class BrokenSales::SaleItemResource < BrokenSales::AssignmentResource
  typelize_from SaleItem

  typelize '"sale_item"'
  attribute :kind do |_sale_item|
    "sale_item"
  end

  typelize :string
  attribute :reference do |sale_item|
    "Order #{order_title(sale_item.sale)}, item #{sale_item.id}"
  end

  typelize :string
  attribute :order_title do |sale_item|
    order_title(sale_item.sale)
  end

  typelize '"shopify" | "woo"', nullable: true
  attribute :store_type do |sale_item|
    sale_store_type(sale_item.sale)
  end

  typelize :string, nullable: true
  attribute :status do |sale_item|
    sale_item.sale.status&.titleize
  end

  typelize :string
  attribute :customer_name do |sale_item|
    sale_item.sale.customer.full_name
  end

  typelize :string, nullable: true
  attribute :amount do |sale_item|
    format_usd(sale_item.expected_revenue)
  end

  typelize :string
  attribute :record_path do |sale_item|
    sale_path(sale_item.sale)
  end

  typelize "{ message: string; last_failed_at: string; pull_path: string; sentry_url: string | null }", nullable: true
  attribute :import_failure do |sale_item|
    failure = params.fetch(:import_failures_by_sale_id)[sale_item.sale_id]
    failure && {
      message: failure.message,
      last_failed_at: format_datetime(failure.last_failed_at),
      pull_path: import_failure_pull_path(failure),
      sentry_url: sentry_event_url(failure.sentry_event_id)
    }
  end

  typelize 'Array<{ kind: "units_not_reserved" | "debt_miscounted" | "variant_not_recorded" | "wrong_variant_recorded" | "not_updating"; text: string }>'
  attribute :consequences do |sale_item|
    failure = params.fetch(:import_failures_by_sale_id)[sale_item.sale_id]
    params.fetch(:impact).consequences(sale_item, reason: params.fetch(:reasons).fetch(sale_item.id), import_failure: failure).map do |consequence|
      {kind: consequence.fetch(:kind).to_s, text: consequence_text(sale_item, consequence, failure)}
    end
  end

  def consequence_text(sale_item, consequence, failure)
    case consequence.fetch(:kind)
    when :units_not_reserved then unreserved_text(consequence.fetch(:units), sale_item.sale.customer.full_name)
    when :debt_miscounted then "#{debt_subject(sale_item)} may be under-ordered: this sale isn't counted in what we owe."
    when :not_updating then "Not updating from #{failure.store_name.titleize} since #{format_date(failure.first_failed_at)}: status and payments here may be out of date."
    when :variant_not_recorded then "History doesn't record which Variant #{customer_subject(sale_item)} bought."
    when :wrong_variant_recorded then "History records the wrong Variant for #{customer_subject(sale_item)}."
    end
  end

  def unreserved_text(units, customer_name)
    return "1 unit for #{customer_name} isn't reserved. It may not arrive on time." if units == 1

    "#{units} units for #{customer_name} aren't reserved. They may not arrive on time."
  end

  def debt_subject(sale_item)
    variant = sale_item.variant
    return product(sale_item).full_title unless variant && !variant.base_model?

    "#{variant.product.full_title} → #{variant.title}"
  end

  def customer_subject(sale_item)
    sale_item.sale.customer.full_name.presence || "this customer"
  end

  def order_title(sale)
    sale.shop_identifier.presence || "Sale #{sale.id}"
  end
end
