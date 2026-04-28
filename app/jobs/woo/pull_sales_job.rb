# frozen_string_literal: true

module Woo
  class PullSalesJob < ApplicationJob
    queue_as :default

    include Gettable
    include Sanitizable

    URL = "https://store.handsomecake.com/wp-json/wc/v3/orders/"
    ORDERS_SIZE = ENV["ORDERS_SIZE"] || 2700
    EDITION_TYPES = ::Variant.types.values
    SYNC_VARIANTS_JOB = Woo::PullVariantsJob.new

    def perform(limit: nil, pages: nil, id: nil)
      woo_orders = if id.present?
        [api_get_order(id)]
      else
        limit ||= ORDERS_SIZE
        api_get_all_orders(limit, pages)
      end
      parsed_orders = parse_all(woo_orders)
      create_sales(parsed_orders)
      nil
    end

    def create_sales(parsed_orders)
      current_order = nil
      pulled_at = Time.zone.now

      parsed_orders.each do |order|
        current_order = order

        ActiveRecord::Base.transaction do
          customer_id = get_customer_id(order[:customer], pulled_at:)
          sale = get_sale(order[:sale].merge(customer_id:), pulled_at:)

          order[:products].each do |order_product|
            product = Product.find_by_woo_id(order_product[:product_woo_id])

            if product.blank?
              product = get_product_from_woo(order_product[:product_woo_id])
            end

            next if product.blank?

            product.with_lock do
              variant = Woo::Variant.import(order_product[:variant])

              sale_item = SaleItem.find_by_woo_id(order_product[:sale_item_woo_id]) || SaleItem.new

              sale_item.assign_attributes({
                price: order_product[:price],
                product:,
                qty: order_product[:qty],
                sale:,
                variant:
              }.compact)

              unless sale_item.save!
                Rails.logger.error "!!! Failed to save SaleItem: #{sale_item.errors.full_messages.join(", ")}"
              end

              sale_item.upsert_woo_info!(store_id: order_product[:sale_item_woo_id], pull_time: pulled_at) if order_product[:sale_item_woo_id].present?
            end
          end
        end
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

    def parse_all(orders)
      orders.map { |order| parse(order) }.compact
    end

    def parse(order)
      return if order.blank?

      shipping = {}
      [order[:shipping], order[:billing]].compact.each do |address|
        address&.each { |k, v| shipping[k] = v.presence || "" }
      end

      {
        sale: {
          address_1: shipping[:address_1],
          address_2: shipping[:address_2],
          city: shipping[:city],
          company: shipping[:company],
          country: shipping[:country],
          discount_total: order[:discount_total],
          note: order[:customer_note],
          postcode: shipping[:postcode],
          shipping_total: order[:shipping_total],
          state: shipping[:state],
          status: order[:status],
          total: order[:total],
          woo_created_at: DateTime.parse(order[:date_created]),
          woo_id: order[:id],
          woo_updated_at: DateTime.parse(order[:date_modified])
        },
        customer: {
          email: shipping[:email].downcase,
          first_name: shipping[:first_name],
          last_name: shipping[:last_name],
          phone: shipping[:phone],
          woo_id: order[:customer_id]
        },
        products: order[:line_items].map { |line_item|
          {
            sale_item_woo_id: line_item[:id],
            price: line_item[:price].to_i + line_item[:total_tax].to_i,
            product_woo_id: line_item[:product_id],
            qty: line_item[:quantity],
            variant: parse_variant(line_item)
          }.compact
        }
      }
    end

    def parse_variant(line_item)
      Woo::Variant.deserialize_from_order_response(line_item)
    end

    def get_customer_id(parsed_customer, pulled_at: Time.zone.now)
      customer = if Customer.woo_id_is_valid? parsed_customer[:woo_id]
        Customer.find_by_woo_id(parsed_customer[:woo_id]) || Customer.new
      else
        Customer.find_or_initialize_by(
          email: parsed_customer[:email]
        )
      end
      customer.assign_attributes(parsed_customer.except(:woo_id, :store_id))
      customer.save!
      customer.upsert_woo_info!(store_id: parsed_customer[:woo_id], pull_time: pulled_at) if Customer.woo_id_is_valid?(parsed_customer[:woo_id])
      customer.id
    end

    def get_sale(parsed_sale, pulled_at: Time.zone.now)
      sale = Sale.find_by_woo_id(parsed_sale[:woo_id]) || Sale.new
      sale.assign_attributes(parsed_sale.except(:woo_id, :store_id))
      sale.save!
      sale.upsert_woo_info!(store_id: parsed_sale[:woo_id], pull_time: pulled_at) if parsed_sale[:woo_id].present?

      sale
    end

    def get_product_from_woo(woo_id)
      job = Woo::PullProductsJob.new
      job.get_and_create_product(woo_id)
      Product.find_by_woo_id(woo_id)
    end

    def get_variant(parsed_variant, product)
      return if parsed_variant.blank?

      SYNC_VARIANTS_JOB.create_variant(
        product:,
        variant_woo_id: parsed_variant[:woo_id],
        variant_types: {
          type: parsed_variant[:type],
          value: parsed_variant[:value]
        }
      )
    end
  end
end
