class PurchaseCreator
  def initialize(purchase_params)
    @purchase_params = purchase_params
    @warehouse_id = purchase_params.delete(:warehouse_id)
  end

  def create
    purchase = Purchase.new(@purchase_params)

    if purchase.save
      return if (
        warehouse = Warehouse.find_by(id: @warehouse_id) ||
          Warehouse.find_by(is_default: true)
      ).nil?

      return if (
        purchased_products = create_purchased_products(purchase, warehouse)
      ).blank?

      matching_sales = linkable_product_sales_for(purchase)
      linked_ids = link_with_product_sales(purchased_products, matching_sales)
      notify_linked_products(linked_ids) if linked_ids.any?
    end

    purchase
  end

  private

  def create_purchased_products(purchase, warehouse)
    Array.new(purchase.amount) do
      warehouse.purchased_products.create(purchase_id: purchase.id)
    end
  end

  def link_with_product_sales(purchased_products, active_product_sales)
    linked_ids = []

    active_product_sales.each do |product_sale|
      available_qty = product_sale.qty

      purchased_products.each_with_index do |purchased_product, index|
        break if available_qty <= 0

        purchased_product.update(product_sale_id: product_sale.id)

        purchased_products = purchased_products[index + 1..]
        linked_ids.push(purchased_product.id)
        available_qty -= 1
      end
    end

    linked_ids
  end

  def notify_linked_products(product_ids)
    product_ids.each do |purchased_product_id|
      Notification.dispatch(
        event: Notification.event_types[:product_purchased],
        context: {purchased_product_id:}
      )
    end
  end

  def linkable_product_sales_for(purchase)
    variation_id = purchase.variation_id
    product_id = purchase.product_id

    ProductSale
      .only_active
      .where(
        variation_id.present? ?
          {variation_id:} :
          {product_id:}
      )
      .limit(purchase.amount)
  end
end
