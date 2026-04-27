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
    missing_product_reference =
      parsed[:product_store_id].present? && Product.find_by_shopify_id(parsed[:product_store_id]).nil?

    return create_title_only_sale_item! if only_product_title?

    ActiveRecord::Base.transaction do
      sale_item.assign_attributes(sale_item_attributes)
      sale_item.save!
    end

    Shopify::PullProductJob.perform_later(parsed[:product_store_id]) if missing_product_reference
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
    return unless resolved_product || imported_edition

    sale_item.assign_attributes(sale_item_attributes)
    sale_item.save!
    sale_item
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

  def resolved_product
    @resolved_product ||=
      existing_product_from_store_id ||
      product_from_payload ||
      product_from_full_title ||
      placeholder_product
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
    Product::Shopify::Importer.import!(parsed_product.merge(store_id: parsed[:product_store_id] || parsed_product[:store_id]))
  end

  def placeholder_product
    return nil if parsed[:product_store_id].blank?

    Product.find_or_create_shopify_placeholder!(store_id: parsed[:product_store_id])
  end

  def imported_edition
    return @imported_edition if defined?(@imported_edition)

    @imported_edition =
      if parsed[:edition_store_id].present?
        find_or_create_edition_from_shopify
      elsif normalized_edition_title.blank? && !base_model_edition_title?
        nil
      else
        create_custom_edition
      end
  end

  def find_or_create_edition_from_shopify
    existing_edition = Edition.find_by_shopify_id(parsed[:edition_store_id])
    return existing_edition if existing_edition
    return nil if parsed.dig(:product, :editions).blank?

    parsed[:product][:editions]
      .map { |parsed_edition| Edition::Shopify::Importer.import!(resolved_product, parsed_edition) }
      .find { |edition| edition.shopify_info&.store_id == parsed[:edition_store_id] }
  end

  def create_custom_edition
    return nil if resolved_product.blank?
    return base_model_edition_for(resolved_product) if base_model_edition_title?
    return nil if normalized_edition_title.blank?

    existing_edition = resolved_product.editions.joins(:version).find_by(versions: {value: normalized_edition_title})
    return existing_edition if existing_edition

    version = resolved_product.versions.create!(value: normalized_edition_title)
    resolved_product.editions.create!(
      version:,
      color: nil,
      size: nil,
      sku: resolved_product.pick_available_sku(normalized_edition_title.parameterize)
    )
  end

  def base_model_edition_title?
    normalized_edition_title == "Default Title"
  end

  def normalized_edition_title
    return @normalized_edition_title if defined?(@normalized_edition_title)

    raw_title = parsed[:edition_title].to_s
    return @normalized_edition_title = nil if raw_title.blank?

    title = Sanitizable.sanitize(raw_title).presence
    @normalized_edition_title = title
  end

  def base_model_edition_for(product)
    return product.base_edition if product.base_edition

    product.build_base_edition
    product.save!
    product.base_edition
  end

  def existing_product_from_store_id
    return nil if parsed[:product_store_id].blank?

    Product.find_by_shopify_id(parsed[:product_store_id])
  end

  def handle_record_invalid(error)
    model_name = error.record.class.name
    detailed_errors = error.record.errors.full_messages.join(", ")
    context_details = [
      "sale_store_id: #{sale.shopify_info&.store_id || sale.shopify_id}",
      "sale_item_store_id: #{parsed[:store_id]}",
      "product_store_id: #{parsed[:product_store_id]}",
      "edition_store_id: #{parsed[:edition_store_id]}",
      "edition_title: #{parsed[:edition_title].presence || "blank"}",
      "full_title: #{parsed[:full_title].presence || "blank"}"
    ].join(", ")

    raise Sale::Shopify::Importer::Error, "Failed to process #{model_name}: #{detailed_errors}\n#{context_details}"
  end
end
