# frozen_string_literal: true

class VariantAssignmentIssues::SaleItemResource < VariantAssignmentIssues::AssignmentResource
  typelize_from SaleItem

  typelize '"sale_item"'
  attribute :kind do |_sale_item|
    "sale_item"
  end

  typelize :string
  attribute :reference do |sale_item|
    "Sale ##{sale_item.sale_id}, item ##{sale_item.id}"
  end

  typelize :number
  attribute :ordered_units do |sale_item|
    sale_item.qty.to_i
  end

  typelize :number
  attribute :linked_units do |sale_item|
    sale_item.purchase_items.size
  end

  typelize :string
  attribute :record_path do |sale_item|
    sale_path(sale_item.sale)
  end
end
