NOTHING_MOVED = 0

class ProductMover
  def initialize(warehouse_id:, purchase: nil, purchased_products_ids: [])
    @warehouse = Warehouse.find(warehouse_id)
    @purchase = purchase
    @purchased_products = PurchasedProduct.where(
      id: purchased_products_ids
    )
  end

  def move
    purchased_products = @purchased_products.presence ||
      @purchase&.purchased_products

    if purchased_products&.any?
      grouped_product_ids = group_by_prev_warehouse(purchased_products)
      if update_location_for(purchased_products)
        notify_on_move(grouped_product_ids)
      end
    else
      return NOTHING_MOVED if @purchase.nil?
      purchased_products = create_purchased_products
      if purchased_products.any?
        notify_on_purchase(purchased_products)
      end
    end

    purchased_products.size
  end

  private

  def create_purchased_products
    Array.new(@purchase.amount) do
      @warehouse.purchased_products.create(purchase_id: @purchase.id)
    end
  end

  def notify_on_purchase(purchased_products)
    purchased_product_ids = purchased_products.pluck(:id)
    Notifier.new(purchased_product_ids:).handle_product_purchase
  end

  def group_by_prev_warehouse(purchased_products)
    purchased_products
      .group_by(&:warehouse_id)
      .transform_values do |purchased_products|
        purchased_products.pluck(:id)
      end
  end

  def notify_on_move(grouped_product_ids)
    grouped_product_ids.each do |prev_warehouse_id, ids|
      Notifier.new(
        purchased_product_ids: ids,
        from_id: prev_warehouse_id,
        to_id: @warehouse.id
      ).handle_warehouse_change
    end
  end

  def update_location_for(purchased_products)
    purchased_products.update_all(warehouse_id: @warehouse.id) > 0
  end
end
