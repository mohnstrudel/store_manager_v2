# frozen_string_literal: true

# Sale::InstallmentBackfill
#
# One-time data fix: Seal Subscriptions' generic "Partial Payment" product was
# being imported and treated like real merchandise before SaleItem#origin_sale_item
# and Product#non_catalog existed. This flags that placeholder product and
# reassigns its existing sale items to the real product each installment was
# actually paying towards, using the same resolution Sale::Shopify::SaleItemImporter
# now applies prospectively.
class Sale::InstallmentBackfill
  PLACEHOLDER_SHOPIFY_ID = "gid://shopify/Product/9499506180425"
  PLACEHOLDER_TITLE = "Unattributed Installment Payment"

  Result = Struct.new(:reassigned_count, :unresolved_sale_item_ids)

  def self.call
    new.call
  end

  def call
    return Result.new(reassigned_count: 0, unresolved_sale_item_ids: []) if placeholder_product.blank?

    flag_placeholder_product!
    reassign_installment_items!
  end

  private

  def placeholder_product
    @placeholder_product ||= Product.find_by(shopify_id: PLACEHOLDER_SHOPIFY_ID)
  end

  def flag_placeholder_product!
    placeholder_product.update!(non_catalog: true, title: PLACEHOLDER_TITLE, full_title: PLACEHOLDER_TITLE)
  end

  def reassign_installment_items!
    reassigned_count = 0
    unresolved_sale_item_ids = []

    placeholder_product.sale_items.find_each do |sale_item|
      resolver = Sale::InstallmentProductResolver.new(sale_item.sale)
      target = resolver.target_product

      if target.blank?
        unresolved_sale_item_ids << sale_item.id
        next
      end

      origin_sale_item = resolver.origin_sale_item

      begin
        # origin_sale_item is the customer's real prior purchase of target, so its
        # variant is the edition they actually bought; nil only resolves on its own
        # when target has no active real variant to require one instead.
        sale_item.update!(product: target, variant: origin_sale_item&.variant, origin_sale_item:)
        reassigned_count += 1
      rescue ActiveRecord::RecordInvalid
        unresolved_sale_item_ids << sale_item.id
      end
    end

    Result.new(reassigned_count:, unresolved_sale_item_ids:)
  end
end
