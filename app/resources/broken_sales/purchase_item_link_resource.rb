# frozen_string_literal: true

class BrokenSales::PurchaseItemLinkResource < BrokenSales::IssueResource
  typelize_from PurchaseItem

  typelize '"purchase_item_link"'
  attribute :kind do |_purchase_item|
    "purchase_item_link"
  end

  typelize :string
  attribute :reason do |purchase_item|
    params.fetch(:reasons)[purchase_item.id]
  end

  typelize :number
  attribute :purchase_id, &:purchase_id

  typelize :string
  attribute :purchase_path do |purchase_item|
    purchase_path(purchase_item.purchase)
  end

  typelize :number
  attribute :sale_item_id, &:sale_item_id

  typelize :string
  attribute :sale_path do |purchase_item|
    sale_path(purchase_item.sale_item.sale)
  end

  typelize :string
  attribute :purchase_product_title do |purchase_item|
    purchase_item.purchase.product&.full_title || MISSING_PRODUCT
  end

  typelize :string
  attribute :purchase_variant_label do |purchase_item|
    variant = purchase_item.purchase.variant
    variant ? assignment_label(variant) : MISSING_VARIANT
  end

  typelize :string
  attribute :sale_product_title do |purchase_item|
    purchase_item.sale_item.product&.full_title || MISSING_PRODUCT
  end

  typelize :string
  attribute :sale_variant_label do |purchase_item|
    variant = purchase_item.sale_item.variant
    variant ? assignment_label(variant) : MISSING_VARIANT
  end

  typelize :number
  attribute :exact_replacements_available do |purchase_item|
    replacements(purchase_item.sale_item).count
  end

  typelize "Array<number>"
  attribute :exact_replacement_ids do |purchase_item|
    replacements(purchase_item.sale_item).ids
  end

  typelize :number
  attribute :remaining_capacity_after_unlink do |purchase_item|
    sale_item = purchase_item.sale_item
    [sale_item.qty.to_i - sale_item.purchase_items_count.to_i + 1, 0].max
  end

  def replacements(sale_item)
    PurchaseItem.where(sale_item_id: nil, product_id: sale_item.product_id, variant_id: sale_item.variant_id).order(:id)
  end
end
