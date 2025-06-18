class ProductMover
  NOTHING_MOVED = 0

  def self.move(**kwargs)
    new(**kwargs).move
  end

  def initialize(warehouse_id:, purchase: nil, purchase_items_ids: [])
    @destination = Warehouse.find(warehouse_id)
    @purchase = purchase
    @initial_products = PurchaseItem.where(
      id: purchase_items_ids
    ).presence || purchase&.purchase_items || []
  end

  def move
    return NOTHING_MOVED if nothing_to_move?
    if relocation?
      relocate_items
      notify_on_relocation
    else
      create_items_at_destination
      notify_on_newly_located_items
    end
    @moved_products.size
  end

  private

  def nothing_to_move?
    @initial_products.blank? && @purchase.nil?
  end

  def relocation?
    @initial_products.any?
  end

  def relocate_items
    @initial_products_grouped_by_origin = group_by_origin(@initial_products)
    @moved_products = @initial_products.map { |pp| pp.relocate_to(@destination.id) }
  end

  def notify_on_relocation
    @initial_products_grouped_by_origin.each do |origin_warehouse_id, items_ids|
      PurchasedNotifier.handle_warehouse_change(
        purchase_item_ids: items_ids,
        from_id: origin_warehouse_id,
        to_id: @destination.id
      )
    end
  end

  def create_items_at_destination
    @moved_products = @purchase.create_purchase_items_in(@destination)
  end

  def notify_on_newly_located_items
    purchase_item_ids = @moved_products.pluck(:id)
    PurchasedNotifier.handle_product_purchase(purchase_item_ids:)
  end

  def group_by_origin(purchase_items)
    purchase_items
      .group_by(&:warehouse_id)
      .transform_values do |purchase_items|
        purchase_items.pluck(:id)
      end
  end
end
