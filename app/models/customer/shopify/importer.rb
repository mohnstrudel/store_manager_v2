# frozen_string_literal: true

class Customer::Shopify::Importer
  class Error < StandardError; end

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
      customer.assign_attributes(parsed.except(:store_info))
      build_new_customer_store_info
      customer.save!

      if parsed[:store_info]
        customer.upsert_shopify_info!(**parsed[:store_info], pull_time: Time.zone.now)
      end
    end

    customer
  rescue ActiveRecord::RecordInvalid => e
    handle_record_invalid(e)
  end

  private

  def find_or_initialize_customer
    @customer = if parsed[:store_info]
      Customer.find_by_shopify_id(parsed[:store_info][:store_id]) || Customer.new
    else
      Customer.new
    end
  end

  def handle_record_invalid(error)
    model_name = error.record.class.name
    detailed_errors = error.record.errors.full_messages.join(", ")
    store_id_details = parsed[:store_info] ? "Customer store_id: #{parsed[:store_info][:store_id]}" : nil
    raise Error, "Failed to process #{model_name}: #{detailed_errors}\n#{store_id_details}".strip
  end

  def build_new_customer_store_info
    return unless customer.new_record? && parsed[:store_info].present?

    customer.store_infos.build(store_name: :shopify, **parsed[:store_info], pull_time: Time.zone.now)
  end
end
