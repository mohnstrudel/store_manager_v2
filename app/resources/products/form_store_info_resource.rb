# frozen_string_literal: true

class Products::FormStoreInfoResource < ApplicationResource
  typelize_from StoreInfo

  typelize :number, nullable: true
  attribute :id, &:id

  attributes :store_name

  typelize :string
  attribute :tag_list do |store_info|
    store_info.tags.map(&:name).join(", ")
  end

  typelize :boolean
  attribute :_destroy do |_store_info|
    false
  end
end
