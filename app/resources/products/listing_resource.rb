# frozen_string_literal: true

class Products::ListingResource < ProductResource
  typelize :string
  attribute :title, &:title

  typelize :string
  attribute :edit_path do |product|
    edit_product_path(product)
  end

  typelize :string, nullable: true
  attribute :thumb_url do |product|
    thumb_url(product)
  end

  typelize "Array<{ id: number; title: string }>"
  attribute :variants do |product|
    product.variants.reject(&:base_model?).map { |variant| {id: variant.id, title: variant.title} }
  end

  typelize :string, nullable: true
  attribute :woo_store_id do |product|
    product.woo_info&.store_id
  end

  typelize :string, nullable: true
  attribute :shopify_id_short do |product|
    product.shopify_info&.id_short
  end

  typelize :string
  attribute :new_purchase_path do |product|
    new_purchase_path(product:)
  end
end
