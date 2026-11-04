# frozen_string_literal: true

class Customer::Woo::Importer
  INVALID_WOO_IDS = [0, "0", ""].freeze
  private_constant :INVALID_WOO_IDS

  attr_reader :parsed_customer, :pulled_at
  private :parsed_customer, :pulled_at

  def self.import(parsed_customer, pulled_at: Time.zone.now)
    new(parsed_customer, pulled_at).import
  end

  def initialize(parsed_customer, pulled_at)
    @parsed_customer = parsed_customer
    @pulled_at = pulled_at
  end

  def import
    customer = find_or_initialize_customer
    customer.assign_attributes(parsed_customer.except(:woo_id, :store_id))
    customer.store_infos.build(store_name: :woo, store_id: woo_id, pull_time: pulled_at) if customer.new_record? && valid_woo_id?
    customer.save!
    customer.upsert_woo_info(store_id: woo_id, pull_time: pulled_at) if valid_woo_id?
    customer
  end

  private

  def find_or_initialize_customer
    if valid_woo_id?
      Customer.find_by_woo_id(woo_id) || Customer.new
    else
      Customer.find_or_initialize_by(email: parsed_customer[:email])
    end
  end

  def valid_woo_id?
    @valid_woo_id = !woo_id.in?(INVALID_WOO_IDS) unless defined?(@valid_woo_id)
    @valid_woo_id
  end

  def woo_id
    parsed_customer[:woo_id]
  end
end
