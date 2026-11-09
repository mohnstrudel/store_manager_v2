# frozen_string_literal: true

class CustomerResource < ApplicationResource
  typelize_from Customer

  attributes :id, :first_name, :last_name

  typelize :string
  attribute :full_name, &:full_name

  attributes :email, :phone

  typelize :string, nullable: true
  attribute :woo_store_id, &:woo_store_id

  typelize :string
  attribute :created_at do |customer|
    formatted_timestamp(customer.created_at)
  end

  typelize :string
  attribute :updated_at do |customer|
    formatted_timestamp(customer.updated_at)
  end

  typelize :string
  attribute :path do |customer|
    customer_path(customer)
  end
end
