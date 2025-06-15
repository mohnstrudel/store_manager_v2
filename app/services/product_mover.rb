class ProductMover
  NOTHING_MOVED = 0

  def initialize(warehouse_id:, purchase: nil, purchased_products_ids: [])
    @destination = Warehouse.find(warehouse_id)
    @purchase = purchase
    @purchased_products = PurchasedProduct.where(
      id: purchased_products_ids
    ).presence || purchase&.purchased_products || []
  end

  def move
    if @purchased_products.any?
      notify_on_move if items_relocated?
    else
      return NOTHING_MOVED if @purchase.nil?
      notify_on_purchase if create_purchased_products.any?
    end

    @purchased_products.size
  end

  private

  def notify_on_move
    @items_grouped_by_origin.each do |origin_warehouse_id, items_ids|
      PurchasedNotifier.new(
        purchased_product_ids: items_ids,
        from_id: origin_warehouse_id,
        to_id: @destination.id
      ).handle_warehouse_change
    end
  end

  def items_relocated?
    @items_grouped_by_origin = groupe_by_origin(@purchased_products)
    @purchased_products.update_all(warehouse_id: @destination.id) > 0
  end

  def groupe_by_origin(purchased_products)
    purchased_products
      .group_by(&:warehouse_id)
      .transform_values do |purchased_products|
        purchased_products.pluck(:id)
      end
  end

  def create_purchased_products
    @purchased_products = Array.new(@purchase.amount) do
      @destination.purchased_products.create(purchase_id: @purchase.id)
    end
  end

  def notify_on_purchase
    purchased_product_ids = @purchased_products.pluck(:id)
    PurchasedNotifier.new(purchased_product_ids:).handle_product_purchase
  end
end
