# frozen_string_literal: true

class Dashboard::DebtResource < Dashboard::SaleDebtResource
  typelize :number
  attribute :sold_amount do |product|
    product.sold_amount.to_i
  end

  typelize :number
  attribute :purchased_amount do |product|
    (product.sale_variant_id.present? ? product.purchased_variants_amount : product.purchased_amount).to_i
  end

  typelize :number
  attribute :debt do |product|
    (product.sale_variant_id.present? ? product.variants_debt : product.debt).to_i
  end
end
