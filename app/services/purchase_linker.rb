class PurchaseLinker
  def initialize(purchase)
    raise ArgumentError, "Missing purchase" if purchase.blank?

    @purchase = purchase
    @purchased_products = purchase.purchased_products
    @limit = purchase.amount
    @edition_id = purchase.edition_id
    @product_id = purchase.product_id
    @linked_ids = []
  end

  def link
    return if @purchased_products.blank?

    product_sales.each do |product_sale|
      remaining = count_linkable(
        product_sale.qty,
        linkable_purchased_products_count
      )

      break if remaining == 0

      @purchased_products.where(product_sale_id: nil).find_each do |purchased_product|
        break if remaining == 0

        purchased_product.update(product_sale_id: product_sale.id)
        @linked_ids.push(purchased_product.id)

        remaining -= 1
      end
    end

    @linked_ids
  end

  private

  def linkable_purchased_products_count
    (@linked_ids.size - @limit).abs
  end

  def count_linkable(qty, limit)
    (qty >= limit) ? limit : qty
  end

  def product_sales
    ProductSale
      .only_active
      .linkable
      .where(
        @edition_id.present? ?
          {edition_id: @edition_id} :
          {product_id: @product_id, edition_id: nil}
      )
  end
end
