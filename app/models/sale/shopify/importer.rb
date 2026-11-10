# frozen_string_literal: true

class Sale::Shopify::Importer
  class Error < StandardError; end

  attr_reader :sale, :parsed
  private :sale, :parsed

  def self.import(parsed_payload)
    raise ArgumentError, "Parsed payload cannot be blank" if parsed_payload.blank?

    new(parsed_payload).update_or_create
  end

  def initialize(parsed_payload)
    @parsed = parsed_payload
  end

  def update_or_create
    import_missing_products
    find_or_initialize_sale

    ActiveRecord::Base.transaction do
      sale.update!(sale_attributes)
      sale.upsert_shopify_info(**parsed[:store_info], pull_time: Time.zone.now)
      reconcile_payment_plans
      update_addresses
      update_or_create_sale_items
      sale.allocate_revenue_to_items
      Sale::ImportFailure.resolve(store_name: "shopify", store_order_id: parsed[:store_info][:store_id])
    end

    sale.link_purchase_items
    sale
  rescue ActiveRecord::RecordInvalid => e
    handle_record_invalid(e)
  end

  private

  def import_missing_products
    store_ids = catalog.missing_product_store_ids(order_updated_at: parsed.dig(:store_info, :ext_updated_at)&.in_time_zone)
    store_ids.each { |store_id| import_product(store_id) }
    catalog.reload if store_ids.any?
  end

  def catalog
    @catalog ||= Sale::Shopify::Catalog.new(parsed[:sale_items])
  end

  def import_product(store_id)
    payload = Shopify::Api::Client.new.fetch_product(store_id)
    return if payload.blank?

    Product::Shopify::Importer.import(Product::Shopify::Parser.parse(payload), inline_variants: true)
  rescue Shopify::Api::Client::Throttled
    raise
  rescue Shopify::Api::Client::ApiError, Product::Shopify::Importer::Error, Variant::Shopify::Importer::Error => e
    raise Error, "Failed to import product #{store_id}: #{e.message}\n#{context_details}"
  end

  def context_details
    [
      "sale_store_id: #{parsed.dig(:store_info, :store_id)}",
      "sale_shopify_id: #{parsed.dig(:sale, :shopify_id)}",
      "sale_shopify_name: #{parsed.dig(:sale, :shopify_name)}",
      "customer_store_id: #{parsed.dig(:customer, :store_info, :store_id)}"
    ].join(", ")
  end

  def find_or_initialize_sale
    @sale = Sale.find_by_shopify_id(parsed[:store_info][:store_id]) || Sale.new
  end

  def sale_attributes
    parsed[:sale]
      .slice(*Sale.attribute_names.map(&:to_sym))
      .merge(customer: Customer::Shopify::Importer.import(parsed[:customer]))
  end

  def reconcile_payment_plans
    SalePaymentPlan.reconcile_sale(sale)
    return if parsed[:payment_plan].blank?

    snapshot = parsed[:payment_plan]
    SalePaymentPlan.reconcile(
      attributes: snapshot.fetch(:attributes).merge(synced_at: Time.current),
      parts: snapshot.fetch(:parts)
    )
  end

  def update_addresses
    return unless parsed.key?(:addresses)

    sale.save_addresses(**address_attributes)
  end

  def address_attributes
    (parsed[:addresses] || {}).reverse_merge(shipping: nil, billing: nil)
  end

  def update_or_create_sale_items
    parsed[:sale_items].each do |parsed_sale_item|
      Sale::Shopify::SaleItemImporter.new(sale, parsed_sale_item, catalog:).import
    end
  end

  def handle_record_invalid(error)
    model_name = error.record.class.name
    detailed_errors = error.record.errors.full_messages.join(", ")

    raise Error, "Failed to process #{model_name}: #{detailed_errors}\n#{context_details}"
  end
end
