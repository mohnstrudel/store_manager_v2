# frozen_string_literal: true

class Sale::Woo::Importer
  class Error < StandardError; end

  attr_reader :parsed_order, :pulled_at, :sale
  private :parsed_order, :pulled_at, :sale

  def self.import(parsed_order, pulled_at: Time.zone.now)
    new(parsed_order, pulled_at).import
  end

  def initialize(parsed_order, pulled_at)
    @parsed_order = parsed_order
    @pulled_at = pulled_at
  end

  def import
    ActiveRecord::Base.transaction do
      upsert_sale
      parsed_order[:products].each { |parsed_item| import_sale_item(parsed_item) }
      sale.allocate_revenue_to_items
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

    return if product.blank?

    product.with_lock do
      variant = Variant::Woo::Importer.import(parsed_item[:variant])

      sale_item = SaleItem.find_by_woo_id(parsed_item[:sale_item_woo_id]) || SaleItem.new

      sale_item.assign_attributes({
        price: parsed_item[:price],
        expected_revenue: parsed_item[:expected_revenue],
        product:,
        qty: parsed_item[:qty],
        sale:,
        variant:
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

  def line_error_message(parsed_item, error)
    "Woo line #{parsed_item[:sale_item_woo_id]} (Woo product #{parsed_item[:product_woo_id]}): " \
      "#{record_label(error.record)}: #{error.message}"
  end

  def record_label(record)
    record.persisted? ? "#{record.class.name} ##{record.id}" : record.class.name
  end
end
