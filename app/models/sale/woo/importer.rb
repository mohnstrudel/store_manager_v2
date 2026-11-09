# frozen_string_literal: true

class Sale::Woo::Importer
  class Error < StandardError; end

  attr_reader :parsed_order, :pulled_at, :sale, :skipped_items
  private :parsed_order, :pulled_at, :sale, :skipped_items

  def self.import(parsed_order, pulled_at: Time.zone.now)
    new(parsed_order, pulled_at).import
  end

  def initialize(parsed_order, pulled_at)
    @parsed_order = parsed_order
    @pulled_at = pulled_at
    @skipped_items = []
  end

  def import
    ActiveRecord::Base.transaction do
      upsert_sale
      parsed_order[:products].each { |parsed_item| import_sale_item(parsed_item) }
      sale.allocate_revenue_to_items
      settle_import_failure
      sale
    end
  end

  private

  def upsert_sale
    parsed_sale = parsed_order[:sale].merge(customer_id: import_customer.id)
    addresses = parsed_order[:addresses]

    @sale = Sale.find_by_woo_id(parsed_sale[:woo_id]) || Sale.new
    sale.assign_attributes(parsed_sale.slice(*Sale.attribute_names.map(&:to_sym)).except(:woo_id, :store_id))
    sale.save!
    sale.upsert_woo_info(store_id: parsed_sale[:woo_id], pull_time: pulled_at) if parsed_sale[:woo_id].present?
    sale.save_addresses(**addresses.reverse_merge(shipping: nil, billing: nil)) unless addresses.nil?
  end

  def import_customer
    Customer::Woo::Importer.import(parsed_order[:customer], pulled_at:)
  end

  def import_sale_item(parsed_item)
    product = find_or_fetch_product(parsed_item[:product_woo_id])

    if product.blank?
      skipped_items << parsed_item
      return
    end

    product.with_lock do
      sale_item = SaleItem.find_by_woo_id(parsed_item[:sale_item_woo_id]) || SaleItem.new

      sale_item.assign_attributes({
        price: parsed_item[:price],
        expected_revenue: parsed_item[:expected_revenue],
        product:,
        qty: parsed_item[:qty],
        sale:,
        variant: line_variant(sale_item, parsed_item[:variant])
      }.compact)

      sale_item.save!
      sale_item.upsert_woo_info(store_id: parsed_item[:sale_item_woo_id], pull_time: pulled_at) if parsed_item[:sale_item_woo_id].present?
    end
  rescue ActiveRecord::RecordInvalid => error
    raise Error, line_error_message(parsed_item, error)
  end

  def find_or_fetch_product(woo_id)
    product = Product.find_by_woo_id(woo_id)
    return product if product.present?

    Product::Woo::Importer.fetch_and_import(woo_id)
    Product.find_by_woo_id(woo_id)
  end

  def line_variant(sale_item, parsed_variant)
    variant = Variant::Woo::Importer.import(parsed_variant)
    return variant if parsed_variant&.dig(:options).present?

    sale_item.variant || variant
  end

  def line_error_message(parsed_item, error)
    "#{line_label(parsed_item)}: #{record_label(error.record)}: #{error.message}"
  end

  def line_label(parsed_item)
    "Woo line #{parsed_item[:sale_item_woo_id]} (Woo product #{parsed_item[:product_woo_id]})"
  end

  def record_label(record)
    record.persisted? ? "#{record.class.name} ##{record.id}" : record.class.name
  end

  def settle_import_failure
    store_order_id = parsed_order[:sale][:woo_id]

    if skipped_items.empty?
      Sale::ImportFailure.resolve(store_name: "woo", store_order_id:)
    else
      Sale::ImportFailure.record(store_name: "woo", store_order_id:, message: skipped_items_message, sentry_event_id: nil, failed_at: pulled_at)
    end
  end

  def skipped_items_message
    skipped_items.map { |parsed_item| "#{line_label(parsed_item)}: product not found" }.join("; ")
  end
end
