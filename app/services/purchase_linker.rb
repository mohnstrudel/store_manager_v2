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

    ProductSale.linkable_for(@purchase).each do |ps|
      break if unlinked_purchased_products.empty?

      remaining = [
        ps.qty,
        @purchase.amount,
        unlinked_purchased_products.size
      ].min

      unlinked_purchased_products.shift(remaining).each do |pp|
        pp.link_with(ps.id)
        @linked_ids << pp.id
      end
    end

    @linked_ids
  end
end
