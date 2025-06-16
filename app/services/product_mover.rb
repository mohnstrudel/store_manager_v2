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
    return NOTHING_MOVED if @purchased_products.blank? && @purchase.nil?
    notify_after_move if items_moved?
    @purchased_products.size
  end

  private

  def notify_after_move
    if @items_grouped_by_origin.present?
      notify_on_relocation
    else
      notify_on_newly_located_items
    end
  end

  def notify_on_relocation
    @items_grouped_by_origin.each do |origin_warehouse_id, items_ids|
      PurchasedNotifier.new(
        purchased_product_ids: items_ids,
        from_id: origin_warehouse_id,
        to_id: @destination.id
      ).handle_warehouse_change
    end
  end

  def notify_on_newly_located_items
    purchased_product_ids = @purchased_products.pluck(:id)
    PurchasedNotifier.new(purchased_product_ids:).handle_product_purchase
  end

  def items_moved?
    if @purchased_products.any?
      @items_grouped_by_origin = groupe_by_origin(@purchased_products)
      @purchased_products.update_all(warehouse_id: @destination.id) > 0
    else
      @purchased_products = Array.new(@purchase.amount) do
        @destination.purchased_products.create(purchase_id: @purchase.id)
      end
      @purchased_products.any?
    end
  end

  def groupe_by_origin(purchased_products)
    purchased_products
      .group_by(&:warehouse_id)
      .transform_values do |purchased_products|
        purchased_products.pluck(:id)
      end
  end
end
