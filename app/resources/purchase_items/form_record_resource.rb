# frozen_string_literal: true

class PurchaseItems::FormRecordResource < ApplicationResource
  typelize_from PurchaseItem

  typelize :number, nullable: true
  attribute :id, &:id

  typelize :string
  attribute :path do |purchase_item|
    purchase_item.persisted? ? purchase_item_path(purchase_item) : ""
  end

  attributes :purchase_id, :sale_item_id, :warehouse_id, :shipping_company_id

  typelize :string
  attribute :length do |purchase_item|
    purchase_item.length.to_s
  end

  typelize :string
  attribute :width do |purchase_item|
    purchase_item.width.to_s
  end

  typelize :string
  attribute :height do |purchase_item|
    purchase_item.height.to_s
  end

  typelize :string
  attribute :weight do |purchase_item|
    purchase_item.weight.to_s
  end

  typelize :string
  attribute :shipping_cost do |purchase_item|
    purchase_item.persisted? ? purchase_item.shipping_cost.to_s : ""
  end

  typelize :string
  attribute :tracking_number do |purchase_item|
    purchase_item.tracking_number.to_s
  end

  typelize :string
  attribute :shipped_at do |purchase_item|
    purchase_item.shipped_at&.to_date&.iso8601.to_s
  end

  typelize "Array<MediaForm>"
  attribute :media do |purchase_item|
    MediaFormResource.attached(purchase_item.media)
  end

  typelize :boolean
  attribute :redirect_to_sale_item do |_purchase_item|
    params[:redirect_to_sale_item] == true
  end
end
