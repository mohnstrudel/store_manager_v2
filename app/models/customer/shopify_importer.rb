# frozen_string_literal: true

class Customer
  class ShopifyImporter
    class CustomerImporterError < StandardError; end

    attr_reader :customer, :parsed
    private :customer, :parsed

    def self.import!(parsed_payload)
      raise ArgumentError, "Parsed payload cannot be blank" if parsed_payload.blank?

      new(parsed_payload).update_or_create!
    end

    def initialize(parsed_payload)
      @parsed = parsed_payload
    end

    def update_or_create!
      find_or_initialize_customer

      ActiveRecord::Base.transaction do
        customer.update!(parsed.except(:store_info))
        update_or_create_store_info!
      end

      customer
    rescue ActiveRecord::RecordInvalid => e
      handle_record_invalid(e)
    end

    private

    # Customers may be guests without Shopify ID
    def find_or_initialize_customer
      @customer = if parsed[:store_info]
        Customer.find_by_shopify_id(parsed[:store_info][:store_id]) || Customer.new
      else
        Customer.new
      end
    end

    def update_or_create_store_info!
      return unless parsed[:store_info]

      store_info_attrs = {
        **parsed[:store_info],
        store_name: :shopify,
        pull_time: Time.zone.now
      }

      store_info = customer.store_infos.find_by(store_name: :shopify)

      if store_info
        store_info.update!(store_info_attrs)
      else
        customer.store_infos.create!(store_info_attrs)
      end
    end

    def handle_record_invalid(e)
      model_name = e.record.class.name
      detailed_errors = e.record.errors.full_messages.join(", ")
      if parsed[:store_info]
        store_id_details = "Customer store_id: #{parsed[:store_info][:store_id]}"
      end
      raise CustomerImporterError, "Failed to process #{model_name}: #{detailed_errors}\n#{store_id_details}"
    end
  end
end
