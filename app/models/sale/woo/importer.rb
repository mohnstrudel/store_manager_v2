# frozen_string_literal: true

class Sale::Woo::Importer
  class << self
    def import_all!(parsed_orders)
      current_order = nil
      pulled_at = Time.zone.now

      parsed_orders.each do |order|
        current_order = order
        import!(order, pulled_at:)
      end
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error "!!! Validation error for order #{current_order&.dig(:sale, :woo_id)}: #{e.message}"
      Rails.logger.error "!!! Failed record: #{e.record&.attributes}"
      raise
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.error "!!! Database error for order #{current_order&.dig(:sale, :woo_id)}: #{e.message}"
      raise
    rescue => e
      Rails.logger.error "!!! Unexpected error for order #{current_order&.dig(:sale, :woo_id)}: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      raise
    end

    def import!(parsed_order, pulled_at: Time.zone.now)
      ActiveRecord::Base.transaction do
        customer = Customer::Woo::Importer.import!(parsed_order[:customer], pulled_at:)
        sale = upsert_sale!(parsed_order[:sale].merge(customer_id: customer.id), addresses: parsed_order[:addresses], pulled_at:)

        parsed_order[:products].each do |parsed_item|
          import_sale_item!(sale, parsed_item, pulled_at:)
        end

        sale.allocate_revenue_to_items!
        sale
      end
    end

    private

    def upsert_sale!(parsed_sale, addresses:, pulled_at:)
      addresses_present = !addresses.nil?
      addresses ||= {}

      sale = Sale.find_by_woo_id(parsed_sale[:woo_id]) || Sale.new
      sale.assign_attributes(parsed_sale.slice(*Sale.attribute_names.map(&:to_sym)).except(:woo_id, :store_id))
      sale.save!
      sale.upsert_woo_info!(store_id: parsed_sale[:woo_id], pull_time: pulled_at) if parsed_sale[:woo_id].present?
      sale.upsert_addresses!(**addresses.reverse_merge(shipping: nil, billing: nil)) if addresses_present

      sale
    end

    def import_sale_item!(sale, parsed_item, pulled_at:)
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

        unless sale_item.save!
          Rails.logger.error "!!! Failed to save SaleItem: #{sale_item.errors.full_messages.join(", ")}"
        end

        sale_item.upsert_woo_info!(store_id: parsed_item[:sale_item_woo_id], pull_time: pulled_at) if parsed_item[:sale_item_woo_id].present?
      end
    end

    def find_or_fetch_product(woo_id)
      product = Product.find_by_woo_id(woo_id)
      return product if product.present?

      Product::Woo::Importer.fetch_and_import(woo_id)
      Product.find_by_woo_id(woo_id)
    end
  end
end
