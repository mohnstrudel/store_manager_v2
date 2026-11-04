# frozen_string_literal: true

class Customer::Woo::Importer
  class << self
    def import!(parsed_customer, pulled_at: Time.zone.now)
      woo_id = parsed_customer[:woo_id]
      valid_woo_id = Customer.woo_id_is_valid?(woo_id)

      customer = if valid_woo_id
        Customer.find_by_woo_id(woo_id) || Customer.new
      else
        Customer.find_or_initialize_by(email: parsed_customer[:email])
      end
      customer.assign_attributes(parsed_customer.except(:woo_id, :store_id))
      customer.store_infos.build(store_name: :woo, store_id: woo_id, pull_time: pulled_at) if customer.new_record? && valid_woo_id
      customer.save!
      customer.upsert_woo_info!(store_id: woo_id, pull_time: pulled_at) if valid_woo_id
      customer
    end
  end
end
