# frozen_string_literal: true

require "securerandom"

class Shopify::ProductCreator
  def initialize(parsed_item: {})
    @parsed_product = parsed_item
  end

  def update_or_create!
    ActiveRecord::Base.transaction do
      find_or_initialize_product
      assign_relation("brands", @parsed_product[:brand])
      assign_relation("sizes", @parsed_product[:size])
      @product.full_title = build_full_title_from_parsed

      generate_sku if @product.sku.blank?

      @product.save!
      update_shopify_store_info!
    end

    Shopify::PullEditionsJob.perform_later(
      @product,
      @parsed_product[:editions]
    )
    Shopify::PullMediaJob.perform_later(
      @product,
      @parsed_product[:media]
    )

    @product
  end

  private

  def find_or_initialize_product
    @product = Product.find_by_shopify_id(@parsed_product[:shopify_id])
    @product ||= find_product_by_shopify_link || Product.new

    @product.assign_attributes(
      title: @parsed_product[:title],
      franchise: Franchise.find_or_create_by(
        title: @parsed_product[:franchise]
      ),
      shape: Shape.find_or_create_by(
        title: @parsed_product[:shape]
      )
    )
  end

  def find_product_by_shopify_link
    return if @parsed_product[:store_link].blank?

    store_info = StoreInfo.find_by(store_name: :shopify, slug: @parsed_product[:store_link])
    store_info&.storable
  end

  def assign_relation(relation_name, parsed_value)
    relation_attrs = build_relation_attrs(relation_name, parsed_value)
    product_relation = @product.public_send(relation_name)
    klass = relation_name.singularize.camelize.constantize

    if parsed_value && !product_relation.exists?(relation_attrs)
      product_relation << klass.find_or_create_by(relation_attrs)
    end
  end

  def build_relation_attrs(relation_name, parsed_value)
    if relation_name == "brands"
      {title: parsed_value}
    elsif relation_name == "sizes"
      {value: parsed_value}
    end
  end

  def build_full_title_from_parsed
    title_part = if @product.title == @product.franchise.title
      @product.title
    else
      "#{@product.franchise.title} — #{@product.title}"
    end

    brand_part = @parsed_product[:brand]
    [title_part, brand_part].compact_blank.join(" | ")
  end

  def generate_sku
    if @parsed_product[:sku].present?
      @product.sku = @parsed_product[:sku]
      return
    end

    base_sku = @product.full_title.parameterize[0..50]
    @product.sku = "#{base_sku}-#{SecureRandom.uuid[0..7]}"
  end

  def update_shopify_store_info!
    shopify_id = @parsed_product[:shopify_id]
    store_link = @parsed_product[:store_link]
    return if shopify_id.blank? && store_link.blank?

    store_info = @product.shopify_info

    updates = {}
    updates[:store_id] = shopify_id if shopify_id.present? && store_info.store_id != shopify_id
    updates[:slug] = store_link if store_link.present? && store_info.slug != store_link

    return if updates.empty?

    # rubocop:disable Rails/SkipsModelValidations -- Intentional for sync operation
    store_info.update_columns(updates) if updates.keys.any?
    # rubocop:enable Rails/SkipsModelValidations
  end
end
