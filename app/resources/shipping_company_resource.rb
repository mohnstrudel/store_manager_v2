# frozen_string_literal: true

class ShippingCompanyResource < ApplicationResource
  typelize_from ShippingCompany

  typelize :string
  attribute :created_at do |shipping_company|
    formatted_timestamp(shipping_company.created_at)
  end

  attributes :id

  typelize :string
  attribute :name do |shipping_company|
    shipping_company.name.to_s
  end

  typelize :string, nullable: true
  attribute :tracking_url do |shipping_company|
    shipping_company.tracking_url.presence
  end

  typelize :string
  attribute :updated_at do |shipping_company|
    formatted_timestamp(shipping_company.updated_at)
  end
end
