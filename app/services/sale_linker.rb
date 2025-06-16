class SaleLinker
  def initialize(sale)
    @sale = sale
  end

  def link
    return unless @sale.active? || @sale.completed?

    @sale.product_sales.linkable.flat_map do |product_sale|
      already_linked_size = product_sale.purchased_products.count
      remaining_size = product_sale.qty - already_linked_size

      next if remaining_size <= 0

      linkable_purchased_products = PurchasedProduct
        .without_product_sales(product_sale.product_id)
        .limit(remaining_size)

      linked_ids = linkable_purchased_products.pluck(:id)

      linkable_purchased_products.update_all(product_sale_id: product_sale.id)

      linked_ids
    end
  end
end
