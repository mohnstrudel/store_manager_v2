# frozen_string_literal: true

class Sale::Shopify::SaleItemImporter
  attr_reader :sale_item, :sale, :parsed
  private :sale_item, :sale, :parsed

  def initialize(sale, parsed_sale_item)
    @sale = sale
    @parsed = parsed_sale_item
  end

  def import!
    return if no_product_data?

    find_or_initialize_sale_item
    return create_title_only_sale_item! if only_product_title?

    ActiveRecord::Base.transaction do
      sale_item.assign_attributes(sale_item_attributes)
      sale_item.save!
    end

    sale_item
  rescue ActiveRecord::RecordInvalid => e
    handle_record_invalid(e)
  end

  private

  def no_product_data?
    parsed[:product_store_id].blank? && parsed[:product].blank? && parsed[:full_title].blank?
  end

  def find_or_initialize_sale_item
    @sale_item = SaleItem.find_by(shopify_id: parsed[:store_id]) || SaleItem.new
  end

  def only_product_title?
    parsed[:full_title].present? && parsed[:edition_store_id].blank? && parsed[:product_store_id].blank?
  end

  def create_title_only_sale_item!
    product = resolved_product
    edition = create_custom_edition_for_product(product)

    return unless product || edition

    sale_item.assign_attributes({
      price: parsed[:price],
      qty: parsed[:qty],
      shopify_id: parsed[:store_id],
      sale: sale,
      product:,
      edition:
    }.compact)
    sale_item.save!

    sale_item
  end

  def resolved_product
    @resolved_product ||=
      product_from_store_id ||
      product_from_payload ||
      product_from_full_title ||
      placeholder_product
  end

  def product_from_store_id
    return nil if parsed[:product_store_id].blank?

    Product.find_by_shopify_id(parsed[:product_store_id])
  end

  def product_from_payload
    return nil if parsed[:product].blank?

    Product::Shopify::Importer.import!(parsed[:product])
  end

  def product_from_full_title
    return nil if parsed[:full_title].blank?

    create_product_from_full_title
  end

  def create_product_from_full_title
    parsed_product = Product::Shopify::Parser.parse({"title" => parsed[:full_title]})
    Product::Shopify::Importer.import!(parsed_product)
  end

  def placeholder_product
    return nil if parsed[:product_store_id].blank?

    Product.find_or_create_shopify_placeholder!(store_id: parsed[:product_store_id])
  end

  def create_custom_edition_for_product(product)
    return nil if product.blank?
    return nil if parsed[:edition_title].blank?

    existing_edition = product.editions.joins(:version).find_by(versions: {value: parsed[:edition_title]})
    return existing_edition if existing_edition

    version = product.versions.create!(value: parsed[:edition_title])
    product.editions.create!(version:, color: nil, size: nil)
  end

  def imported_edition
    return find_or_create_edition_from_shopify if parsed[:edition_store_id].present?
    return nil if parsed[:edition_title].blank?

    create_custom_edition_for_product(resolved_product)
  end

  def sale_item_attributes
    {
      price: parsed[:price],
      qty: parsed[:qty],
      shopify_id: parsed[:store_id],
      sale: sale,
      product: resolved_product,
      edition: imported_edition
    }.compact
  end

  def find_or_create_edition_from_shopify
    existing_edition = Edition.find_by_shopify_id(parsed[:edition_store_id])
    return existing_edition if existing_edition
    return nil unless parsed[:product] && parsed[:product][:editions]

    parsed[:product][:editions]
      .map { |parsed_edition| Edition::Shopify::Importer.import!(resolved_product, parsed_edition) }
      .find { |edition| edition.shopify_info&.store_id == parsed[:edition_store_id] }
  end

  def handle_record_invalid(error)
    model_name = error.record.class.name
    detailed_errors = error.record.errors.full_messages.join(", ")
    raise Sale::Shopify::Importer::Error, "Failed to process #{model_name}: #{detailed_errors}"
  end
end
