# frozen_string_literal: true

class Products::FormProductResource < ApplicationResource
  typelize_from Product

  typelize :number, nullable: true
  attribute :id, &:id

  attributes :title

  typelize :string, nullable: true
  attribute :description_html do |product|
    product.description.body&.to_html
  end

  typelize :number, nullable: true
  attribute :franchise_id, &:franchise_id

  attributes :shape

  typelize "Array<number>"
  attribute :brand_ids, &:brand_ids

  typelize :string
  attribute :path do |product|
    product.persisted? ? product_path(product) : ""
  end

  many :variants, resource: Products::FormVariantResource

  many :store_infos, resource: Products::FormStoreInfoResource

  typelize "Array<Media>"
  attribute :media do |product|
    MediaResource.attached(product.media)
  end
end
