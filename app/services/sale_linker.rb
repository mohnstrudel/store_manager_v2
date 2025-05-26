class SaleLinker
  def initialize(sale)
    @sale = sale
  end

  def link
    return unless @sale.active? || @sale.completed?

    @sale.product_sales.linkable.flat_map do |product_sale|
      already_linked = product_sale.purchased_products.count
      needed = product_sale.qty - already_linked

      next if needed <= 0

      purchased_products_to_link = PurchasedProduct
        .without_product_sales(product_sale.product_id)
        .limit(needed)

      linked_ids = purchased_products_to_link.pluck(:id)

      purchased_products_to_link.update_all(product_sale_id: product_sale.id)

      linked_ids
    end
  end
end
