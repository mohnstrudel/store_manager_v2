# frozen_string_literal: true

class Shopify::EditionCreator
  def initialize(product, parsed_edition)
    raise ArgumentError, "Expected a Product" unless product.is_a?(Product)

    @product = product
    @parsed_edition = parsed_edition.with_indifferent_access
  end

  def update_or_create!
    return if @parsed_edition[:options].blank?

    edition_attrs = find_or_create_edition_attrs
    return if edition_attrs.blank?

    ActiveRecord::Base.transaction do
      @edition = find_or_initialize(edition_attrs)
      @edition.assign_attributes(**edition_attrs)
      @edition.save!
      update_shopify_store_info!
    end

    @edition
  end

  private

  def find_or_create_edition_attrs
    attributes = {}

    @parsed_edition[:options].each do |option|
      case option[:name]
      when "Color"
        attributes[:color] = Color.find_or_create_by(value: option[:value])
        @product.colors |= [attributes[:color]]
      when "Size", "Scale"
        attributes[:size] = Size.find_or_create_by(value: option[:value])
        @product.sizes |= [attributes[:size]]
      when "Version", "Edition", "Variante", "Variants"
        attributes[:version] = Version.find_or_create_by(value: option[:value])
        @product.versions |= [attributes[:version]]
      end
    end

    attributes
  end

  def find_or_initialize(attrs)
    existing_edition = Edition.find_by_shopify_id(@parsed_edition[:id])
    return existing_edition if existing_edition && existing_edition.product_id == @product.id

    @product.editions.where(attrs).first_or_initialize
  end

  def update_shopify_store_info!
    shopify_id = @parsed_edition[:id]
    return if shopify_id.blank?

    store_info = @edition.shopify_info || @edition.store_infos.shopify.new

    updates = {}
    updates[:store_id] = shopify_id if store_info.store_id != shopify_id
    updates[:pull_time] = Time.zone.now

    if @parsed_edition[:store_info]
      updates[:ext_created_at] = @parsed_edition[:store_info][:ext_created_at]
      updates[:ext_updated_at] = @parsed_edition[:store_info][:ext_updated_at]
    end

    return if updates.empty?

    if store_info.persisted?
      # rubocop:disable Rails/SkipsModelValidations
      store_info.update_columns(updates)
      # rubocop:enable Rails/SkipsModelValidations
    else
      store_info.assign_attributes(updates)
      store_info.save!
    end
  end
end
