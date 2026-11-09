# frozen_string_literal: true

class Product::Shopify::Importer
  class Error < StandardError; end

  attr_reader :parsed, :product, :inline_variants, :force
  private :parsed, :product, :inline_variants, :force

  def self.import(parsed_payload, inline_variants: false, force: false)
    raise ArgumentError, "Parsed payload cannot be blank" if parsed_payload.blank?

    new(parsed_payload, inline_variants:, force:).update_or_create
  end

  def initialize(parsed_payload, inline_variants: false, force: false)
    @parsed = parsed_payload
    @inline_variants = inline_variants
    @force = force
  end

  def update_or_create
    update_or_create_product
    import_variants
    Shopify::ImportMediaJob.perform_later(product, parsed[:media], force:) if parsed[:media]

    product
  end

  private

  def update_or_create_product
    ActiveRecord::Base.transaction do
      find_or_initialize_product
      product.assign_attributes(
        title: parsed[:title],
        franchise: Franchise.find_or_create_by(title: parsed[:franchise]),
        shape: parsed[:shape].presence || Product.default_shape,
        description: normalize_description_html(parsed[:description]),
        published_at: parsed[:published_at]
      )
      assign_brand
      assign_size
      product.full_title = product.generate_full_title
      product.build_base_variant(sku: base_variant_sku)
      product.save!

      if parsed[:store_id]
        product.upsert_shopify_info(
          store_id: parsed[:store_id],
          slug: parsed[:store_link],
          ext_created_at: parsed.dig(:store_info, :ext_created_at),
          ext_updated_at: parsed.dig(:store_info, :ext_updated_at),
          tag_list: parsed[:tags],
          pull_time: Time.zone.now
        )
      end
    end
  rescue ActiveRecord::RecordInvalid => e
    handle_record_invalid(e)
  end

  def find_or_initialize_product
    @product = Product.find_by_shopify_id(parsed[:store_id]) if parsed[:store_id]
    @product = find_by_store_link if product.nil? && parsed[:store_link].present?
    if product.nil?
      @product = Product.find_storeless_match_for_shopify(
        franchise_title: parsed[:franchise],
        product_title: parsed[:title],
        shape_title: parsed[:shape],
        brand_titles: parsed[:brand],
        size_values: parsed[:size]
      )
    end
    @product ||= Product.new
  end

  def find_by_store_link
    StoreInfo.find_by(store_name: :shopify, slug: parsed[:store_link])&.storable
  end

  def normalize_description_html(html)
    return html if html.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css("li > p, li > div").each do |node|
      node.add_next_sibling(node.children)
      node.remove
    end
    doc.to_html
  end

  def assign_brand
    return unless parsed[:brand]

    brand = Brand.find_or_create_by(title: parsed[:brand])
    product.brands << brand unless product.brands.exists?(brand.id)
  end

  def assign_size
    return unless parsed[:size]

    size = Size.find_or_create_by(value: parsed[:size])
    product.sizes << size unless product.sizes.exists?(size.id)
  end

  def base_variant_sku
    return parsed[:sku] if parsed[:variants].blank?

    single_variant_variant = parsed[:variants].one? && parsed[:variants].first[:is_single_variant]
    return parsed[:sku] if single_variant_variant

    nil
  end

  def handle_record_invalid(error)
    model_name = error.record.class.name
    detailed_errors = error.record.errors.full_messages.join(", ")

    raise Error, "Failed to process #{model_name}: #{detailed_errors}"
  end

  def import_variants
    return if parsed[:variants].blank?

    if inline_variants
      Variant::Shopify::Importer.import_all(product, converted_variants)
    else
      Shopify::PullVariantsJob.perform_later(product, converted_variants)
    end
  end

  def converted_variants
    return parsed[:variants] unless parsed[:variants].any? { |variant| variant[:selling_price].present? }

    conversion = ExchangeRate.eur_to_usd_conversion(date: Time.zone.today)

    parsed[:variants].map do |variant|
      variant.merge(
        usd_conversion_rate: conversion.rate,
        usd_conversion_date: conversion.effective_date
      )
    end
  end
end
