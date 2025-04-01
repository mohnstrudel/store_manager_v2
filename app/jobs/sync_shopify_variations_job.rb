class SyncShopifyVariationsJob < ApplicationJob
  queue_as :default

  include Sanitizable

  def perform(product, parsed_variations)
    find_or_create_variations(product, parsed_variations)
  end

  private

  def create_attrs(variant)
    return if variant["options"].blank?

    attributes = {}

    variant["options"].each do |option|
      case option["name"]
      when "Color"
        attributes[:color] = Color.find_or_create_by(value: option["value"])
      when "Size", "Scale"
        attributes[:size] = Size.find_or_create_by(value: option["value"])
      when "Version", "Edition"
        attributes[:version] = Version.find_or_create_by(value: option["value"])
      end
    end

    attributes
  end

  def find_or_create_variations(product, variants)
    variants.each do |variant|
      variant = variant.with_indifferent_access

      attrs = create_attrs(variant)

      next if attrs.blank?

      variation = Variation
        .where(
          product:,
          shopify_id: variant["id"]
        )
        .or(Variation.where(
          product:,
          shopify_id: nil,
          **attrs
        ))
        .first_or_initialize

      variation.assign_attributes(shopify_id: variant["id"], **attrs)

      variation.save
    end
  end
end
