class PurchaseSaleLinker
  def initialize(
    purchase: nil,
    sale: nil
  )
    @purchase = purchase
    @sale = sale
  end

  def link
    if @purchase.present?
      link_purchase_to_product_sales
    else
      return unless @sale.active? || @sale.completed?
      link_sale_to_purchased_products
    end
  end

  private

  def matching_sales
    variation_id = @purchase.variation_id
    product_id = @purchase.product_id

    ProductSale
      .only_active
      .where(
        variation_id.present? ?
          {variation_id:} :
          {product_id:}
      )
      .limit(@purchase.amount)
  end

  def link_purchase_to_product_sales
    purchased_products = @purchase.purchased_products
    linked_ids = []

    matching_sales.each do |product_sale|
      available_qty = product_sale.qty

      purchased_products.each_with_index do |purchased_product, index|
        break if available_qty <= 0

        purchased_product.update(product_sale_id: product_sale.id)
        linked_ids.push(purchased_product.id)
        available_qty -= 1
      end
    end

    linked_ids
  end

  def link_sale_to_purchased_products
    @sale.product_sales.flat_map do |product_sale|
      next if product_sale.purchased_products.size >= product_sale.qty

      purchased_products_to_link = PurchasedProduct
        .without_product_sales(product_sale.product_id)
        .limit(product_sale.qty)

      linked_ids = purchased_products_to_link.pluck(:id)

      purchased_products_to_link.update_all(product_sale_id: product_sale.id)

      linked_ids
    end
  end
end
