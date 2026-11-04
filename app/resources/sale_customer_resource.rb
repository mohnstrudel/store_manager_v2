# frozen_string_literal: true

class SaleCustomerResource < ApplicationResource
  typelize_from Customer

  attributes :id

  typelize :string
  attribute :path do |customer|
    customer_path(customer)
  end

  attributes :first_name, :last_name

  typelize :string
  attribute :full_name, &:full_name

  attributes :email

  typelize :string, nullable: true
  attribute :shopify_id_short do |customer|
    customer.shopify_info&.id_short
  end

  typelize :string
  attribute :shop_admin_url do |customer|
    customer_shop_link(customer)
  end
end
