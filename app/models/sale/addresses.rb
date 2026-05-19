# frozen_string_literal: true

module Sale::Addresses
  extend ActiveSupport::Concern

  ADDRESS_ATTRIBUTES = %i[
    first_name
    last_name
    email
    phone
    company
    address_1
    address_2
    city
    state
    postcode
    country
  ].freeze
  ADDRESS_COMPARISON_ATTRIBUTES = ADDRESS_ATTRIBUTES - %i[email phone]

  included do
    has_many :addresses, class_name: "SaleAddress", dependent: :destroy, inverse_of: :sale
    has_one :shipping_address, -> { shipping }, class_name: "SaleAddress",
      dependent: nil, inverse_of: :sale
    has_one :billing_address, -> { billing }, class_name: "SaleAddress",
      dependent: nil, inverse_of: :sale
  end

  def billing_differs_from_shipping?
    return false unless shipping_address && billing_address

    comparable_address_attributes(shipping_address) != comparable_address_attributes(billing_address)
  end

  def upsert_addresses!(shipping:, billing:)
    upsert_address!(:shipping, shipping)
    upsert_address!(:billing, billing)
  end

  private

  def upsert_address!(kind, attributes)
    attributes = normalize_address_attributes(attributes)
    address = addresses.find_or_initialize_by(kind:)

    if blank_address_attributes?(attributes)
      address.destroy! if address.persisted?
      association(:"#{kind}_address").reset
      return
    end

    address.assign_attributes(attributes)
    address.save!
    association(:"#{kind}_address").target = address
  end

  def normalize_address_attributes(attributes)
    return {} if attributes.blank?

    case attributes
    when SaleAddress
      attributes.attributes.symbolize_keys.slice(*ADDRESS_ATTRIBUTES)
    else
      attributes.to_h.with_indifferent_access.slice(*ADDRESS_ATTRIBUTES)
    end
  end

  def blank_address_attributes?(attributes)
    attributes.values.all?(&:blank?)
  end

  def comparable_address_attributes(address)
    normalize_address_attributes(address)
      .slice(*ADDRESS_COMPARISON_ATTRIBUTES)
      .transform_values { |value| value.to_s.strip.presence }
  end
end
