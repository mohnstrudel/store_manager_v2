# frozen_string_literal: true

module SaleItem::Installments
  extend ActiveSupport::Concern

  included do
    scope :non_installment, -> { where(origin_sale_item_id: nil) }
  end

  def apply_installment_origin(origin_item)
    self.skip_purchase_relink = true
    self.skip_variant_assignability_check = true

    if origin_item
      update!(origin_sale_item: origin_item, product: origin_item.product, variant: origin_item.variant)
    else
      update!(origin_sale_item: nil, product: Product.seal_installment_placeholder, variant: nil)
    end
  ensure
    self.skip_purchase_relink = false
    self.skip_variant_assignability_check = false
  end
end
