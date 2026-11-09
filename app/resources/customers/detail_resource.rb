# frozen_string_literal: true

class Customers::DetailResource < CustomerResource
  typelize :string, nullable: true
  attribute :shopify_id do |customer|
    customer.shopify_info&.store_id
  end

  typelize :string, nullable: true
  attribute :shopify_id_short do |customer|
    customer.shopify_info&.id_short
  end
end
