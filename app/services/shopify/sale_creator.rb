class Shopify::SaleCreator
  class OrderProcessingError < StandardError; end

  def initialize(parsed_order)
    @parsed_order = parsed_order
    validate_parsed_order!
  end

  def update_or_create!
    ActiveRecord::Base.transaction do
      customer = find_or_create_customer!
      update_or_create_sale!(customer)
      update_or_create_product_sales!
    end
  rescue ActiveRecord::RecordInvalid => e
    raise OrderProcessingError, "Failed to process. #{e.message}"
  end

  private

  def validate_parsed_order!
    raise ArgumentError, "Order data must be a Hash" unless @parsed_order.is_a?(Hash)
    raise ArgumentError, "Order data is required" if @parsed_order.blank?
    raise ArgumentError, "Customer data is required" if @parsed_order[:customer].blank?
    raise ArgumentError, "Sale data is required" if @parsed_order[:sale].blank?
    raise ArgumentError, "Product sales data is required" if @parsed_order[:product_sales].blank?
  end

  def find_or_create_customer!
    existing_customer = Customer.find_by(
      shopify_id: @parsed_order[:customer][:shopify_id]
    )
    existing_customer || Customer.create!(@parsed_order[:customer])
  end

  def update_or_create_sale!(customer)
    existing_sale = Sale.find_by(
      shopify_id: @parsed_order[:sale][:shopify_id]
    )
    if existing_sale
      existing_sale.update!(customer:)
    else
      Sale.create!(customer:, **@parsed_order[:sale])
    end
  end

  def update_or_create_product_sales!
    sale = Sale.find_by!(shopify_id: @parsed_order[:sale][:shopify_id])

    @parsed_order[:product_sales].each do |parsed_ps|
      if product_sale_is_corrupted(**parsed_ps)
        product, variation = find_or_create_product_variation_by_title!(parsed_ps)
      end

      product ||= find_or_create_product(parsed_ps)
      variation ||= find_or_create_variation!(parsed_ps, product)

      product_sale = ProductSale.find_or_initialize_by(
        shopify_id: parsed_ps[:shopify_id]
      )

      product_sale.assign_attributes(
        price: parsed_ps[:price],
        qty: parsed_ps[:qty],
        product:,
        variation:,
        sale:
      )

      product_sale.save!
    end
  end

  def product_sale_is_corrupted(
    full_title:,
    shopify_product_id:,
    shopify_variation_id:,
    **_rest
  )
    full_title.present? &&
      shopify_variation_id.blank? &&
      shopify_product_id.blank?
  end

  def find_or_create_product(parsed_ps)
    Product.find_by(shopify_id: parsed_ps[:shopify_product_id]) ||
      Shopify::ProductCreator
        .new(parsed_product: parsed_ps[:product])
        .update_or_create
  end

  def find_or_create_variation!(parsed_ps, product)
    return if parsed_ps[:variation_title].blank?

    existing_variation = Variation.find_by(
      shopify_id: parsed_ps[:shopify_variation_id]
    )
    return existing_variation if existing_variation

    create_variations_for_product!(parsed_ps[:product][:variations], product)
    Variation.find_by!(shopify_id: parsed_ps[:shopify_variation_id])
  end

  def create_variations_for_product!(parsed_variations, product)
    parsed_variations.each do |v|
      Shopify::VariationCreator.new(product, v).update_or_create!
    end
  end

  def find_or_create_product_variation_by_title!(parsed_product_sale)
    product = Shopify::ProductCreator
      .new(parsed_title: parsed_product_sale[:full_title])
      .update_or_create_by_title

    existing_variation = product.variations.find do |v|
      v.title == parsed_product_sale[:variation_title]
    end
    return [product, existing_variation] if existing_variation

    product.versions.create!(
      value: parsed_product_sale[:variation_title]
    )
    product.build_variations
    product.save!

    [product, product.variations.last]
  end
end
