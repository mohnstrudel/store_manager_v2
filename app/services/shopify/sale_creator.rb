class Shopify::SaleCreator
  class OrderProcessingError < StandardError; end

  def initialize(parsed_item:)
    validate_input!(parsed_item)
    @parsed_order = parsed_item
    @sale_shopify_id = parsed_item[:sale][:shopify_id]
  end

  def update_or_create!
    ActiveRecord::Base.transaction do
      prepare_customer
      prepare_sale
      update_or_create_sale_items!
      linked_ids = @sale.link_with_purchase_items
      notify_customers(linked_ids)
    end
  rescue ActiveRecord::RecordInvalid => e
    model_name = e.record.class.name
    detailed_errors = e.record.errors.full_messages.join(", ")

    raise OrderProcessingError, "Failed to process #{model_name}: #{detailed_errors}"
  end

  private

  def validate_input!(parsed_item)
    raise ArgumentError, "parsed_item must be a Hash" unless parsed_item.is_a?(Hash)
    raise ArgumentError, "parsed_item cannot be blank" if parsed_item.blank?
    raise ArgumentError, "parsed_item[:sale] cannot be blank" if parsed_item[:sale].blank?
    raise ArgumentError, "parsed_item[:customer] cannot be blank" if parsed_item[:customer].blank?
    raise ArgumentError, "parsed_item[:sale_items] cannot be blank" if parsed_item[:sale_items].blank?
  end

  def prepare_customer
    @customer = update_or_create_with!("customer")
  end

  def prepare_sale
    @sale = update_or_create_with!("sale")
  end

  def update_or_create_with!(class_name)
    record = record_for(class_name)
    record.update!(parsed_data_for(class_name))
    record
  end

  def record_for(class_name)
    klass = class_name.camelize.constantize
    klass.find_by(
      shopify_id: @parsed_order[class_name.to_sym][:shopify_id]
    ) || klass.new
  end

  def parsed_data_for(class_name)
    if class_name == "customer"
      @parsed_order[:customer]
    elsif class_name == "sale"
      raise StandardError, "@customer cannot be blank" if @customer.blank?
      @parsed_order[:sale].merge(customer: @customer)
    end
  end

  def update_or_create_sale_items!
    @parsed_order[:sale_items].each do |parsed_ps|
      if having_only_product_title?(**parsed_ps)
        product = create_product_with(parsed_ps[:full_title])
        edition = find_or_create_edition_with(
          parsed_ps[:edition_title],
          product
        )
      else
        product = find_or_create_product!(
          parsed_ps[:shopify_product_id],
          parsed_ps[:product]
        )
        edition = find_or_create_edition!(
          parsed_ps[:shopify_edition_id],
          parsed_ps[:product][:editions],
          product
        )
      end

      sale_item = SaleItem.find_or_initialize_by(
        shopify_id: parsed_ps[:shopify_id]
      )

      sale_item.assign_attributes(
        price: parsed_ps[:price],
        qty: parsed_ps[:qty],
        product:,
        edition:,
        sale: @sale
      )

      sale_item.save!
    end
  end

  def having_only_product_title?(
    full_title:,
    shopify_product_id:,
    shopify_edition_id:,
    edition_title:,
    **_rest
  )
    full_title.present? &&
      shopify_edition_id.blank? &&
      shopify_product_id.blank?
  end

  def create_product_with(parsed_title)
    Shopify::ProductFromTitleCreator
      .new(api_title: parsed_title)
      .call
  end

  def find_or_create_product!(shopify_product_id, parsed_product)
    Product.find_by(shopify_id: shopify_product_id) ||
      Shopify::ProductCreator
        .new(parsed_item: parsed_product)
        .update_or_create!
  end

  def find_or_create_edition_with(edition_title, product)
    return if edition_title.blank?

    existing_edition = product.editions.find do |v|
      v.title == edition_title
    end
    return existing_edition if existing_edition

    product.versions.create!(value: edition_title)
    product.build_editions
    product.save!

    product.editions.last
  end

  def find_or_create_edition!(shopify_edition_id, parsed_editions, product)
    existing_edition = Edition.find_by(
      shopify_id: shopify_edition_id
    )
    return existing_edition if existing_edition

    if parsed_editions
      editions = parsed_editions.map do |parsed_edition|
        Shopify::EditionCreator.new(product, parsed_edition).update_or_create!
      end
      editions.compact_blank.find { |edition| edition.shopify_id == shopify_edition_id }
    end
  end

  def notify_customers(linked_ids)
    PurchasedNotifier.new(purchase_item_ids: linked_ids).handle_product_purchase
  end
end
