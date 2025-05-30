class Shopify::SaleCreator
  class OrderProcessingError < StandardError; end

  def initialize(parsed_item:)
    @parsed_order = parsed_item
    validate_parsed_order!
    @sale_shopify_id = parsed_item[:sale][:shopify_id]
  end

  def update_or_create!
    ActiveRecord::Base.transaction do
      customer = update_or_create_customer!
      sale = update_or_create_sale!(customer)
      update_or_create_product_sales!(sale)
      linked_ids = SaleLinker.new(sale).link
      notify_customers(linked_ids)
    end
  rescue ActiveRecord::RecordInvalid => e
    model_name = e.record.class.name
    detailed_errors = e.record.errors.full_messages.join(", ")

    raise OrderProcessingError, "Failed to process #{model_name}: #{detailed_errors}"
  end

  private

  def validate_parsed_order!
    raise ArgumentError, "Order data must be a Hash" unless @parsed_order.is_a?(Hash)
    raise ArgumentError, "Order data is required" if @parsed_order.blank?
    raise ArgumentError, "Customer data is required" if @parsed_order[:customer].blank?
    raise ArgumentError, "Sale data is required" if @parsed_order[:sale].blank?
    raise ArgumentError, "Product sales data is required" if @parsed_order[:product_sales].blank?
  end

  def update_or_create_customer!
    customer = Customer.find_by(
      shopify_id: @parsed_order[:customer][:shopify_id]
    ) || Customer.new
    customer.update!(@parsed_order[:customer])
    customer
  end

  def update_or_create_sale!(customer)
    sale = Sale.find_by(
      shopify_id: @sale_shopify_id
    ) || Sale.new
    sale.update!(customer:, **@parsed_order[:sale])
    sale
  end

  def find_or_create_product(shopify_product_id, parsed_product)
    Product.find_by(shopify_id: shopify_product_id) ||
      Shopify::ProductCreator
        .new(parsed_item: parsed_product)
        .update_or_create!
  end

  def update_or_create_product_sales!(sale)
    @parsed_order[:product_sales].each do |parsed_ps|
      if product_sale_is_corrupted(**parsed_ps)
        product, edition = find_or_create_product_edition_by_title!(parsed_ps)
      end

      product ||= find_or_create_product(
        parsed_ps[:shopify_product_id],
        parsed_ps[:product]
      )
      edition ||= find_or_create_edition(parsed_ps, product)

      product_sale = ProductSale.find_or_initialize_by(
        shopify_id: parsed_ps[:shopify_id]
      )

      product_sale.assign_attributes(
        price: parsed_ps[:price],
        qty: parsed_ps[:qty],
        product:,
        edition:,
        sale:
      )

      product_sale.save!
    end
  end

  def product_sale_is_corrupted(
    full_title:,
    shopify_product_id:,
    shopify_edition_id:,
    **_rest
  )
    full_title.present? &&
      shopify_edition_id.blank? &&
      shopify_product_id.blank?
  end

  def find_or_create_edition(parsed_ps, product)
    return if parsed_ps[:edition_title].blank?

    if parsed_ps[:shopify_edition_id].present?
      existing_edition = Edition.find_by(
        shopify_id: parsed_ps[:shopify_edition_id]
      )
      return existing_edition if existing_edition
    end

    if parsed_ps[:product] && parsed_ps[:product][:editions]
      editions = parsed_ps[:product][:editions].map do |parsed_edition|
        Shopify::EditionCreator.new(product, parsed_edition).update_or_create!
      end
      editions.compact_blank.find { |edition| edition.shopify_id == parsed_ps[:shopify_edition_id] }
    end
  end

  def find_or_create_product_edition_by_title!(parsed_product_sale)
    return if parsed_product_sale[:edition_title].blank?
    return if parsed_product_sale[:shopify_edition_id].blank?

    product = Shopify::ProductCreator
      .new(parsed_title: parsed_product_sale[:full_title])
      .update_or_create_by_title

    existing_edition = product.editions.find do |v|
      v.title == parsed_product_sale[:edition_title]
    end
    return [product, existing_edition] if existing_edition

    product.versions.create!(
      value: parsed_product_sale[:edition_title]
    )
    product.build_editions
    product.save!

    [product, product.editions.last]
  end

  def notify_customers(linked_ids)
    Notifier.new(purchased_product_ids: linked_ids).handle_product_purchase
  end
end
