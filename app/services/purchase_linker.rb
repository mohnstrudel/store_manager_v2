class PurchaseLinker
  def initialize(purchase)
    raise ArgumentError, "Missing purchase" if purchase.blank?

    @purchase = purchase
    @edition_id = purchase.edition_id
    @product_id = purchase.product_id
    @linked_ids = []
  end

  def link
    return if @purchase.purchased_products.blank?

    unlinked_purchased_products = @purchase.purchased_products.where(product_sale_id: nil).to_a

    linkable_product_sales.each do |ps|
      break if unlinked_purchased_products.empty?

      remaining = [
        ps.qty,
        @purchase.amount,
        unlinked_purchased_products.size
      ].min

      unlinked_purchased_products.shift(remaining).each do |pp|
        link_purchased_with_sold(pp, ps.id)
        save_linked_id(pp.id)
      end
    end

    @linked_ids
  end

  private

  def linkable_product_sales
    ProductSale
      .only_active
      .linkable
      .where(
        @edition_id.present? ?
          {edition_id: @edition_id} :
          {product_id: @product_id, edition_id: nil}
      )
  end

  def link_purchased_with_sold(purchased_product, product_sale_id)
    purchased_product.update(product_sale_id:)
  end

  def save_linked_id(purchased_product_id)
    @linked_ids.push(purchased_product_id)
  end
end
