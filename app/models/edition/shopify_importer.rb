# frozen_string_literal: true

class Edition
  class ShopifyImporter
    attr_reader :product, :parsed, :edition
    private :product, :parsed, :edition

    def self.import!(product, parsed_payload)
      raise ArgumentError, "Product cannot be blank" if product.blank?
      raise ArgumentError, "Payload cannot be blank" if payload.blank?

      new(product, parsed_payload).update_or_create!
    end

    def initialize(product, parsed_payload)
      @product = product
      @parsed = parsed_payload
    end

    def update_or_create!
      update_or_create_edition!
      update_shopify_store_info! if parsed[:shopify_id]

      edition
    end

    private

    def update_or_create_edition!
      ActiveRecord::Base.transaction do
        find_or_initialize_edition
        edition.assign_attributes(**edition_attrs)
        edition.save!
      end
    end

    def find_or_initialize_edition
      if parsed[:shopify_id]
        @edition = Edition.find_by_shopify_id(parsed[:shopify_id])
        return
      end

      if @edition.nil? || @edition&.product_id != product.id
        @edition = product.editions.where(edition_attrs).first_or_initialize
      end
    end

    def edition_attrs
      @edition_attrs ||= build_edition_attrs
    end

    def build_edition_attrs
      attributes = {}

      parsed[:options].each do |option|
        case option[:name]
        when "Color"
          attributes[:color] = Color.find_or_create_by(value: option[:value])
          product.colors |= [attributes[:color]]
        when "Size", "Scale"
          attributes[:size] = Size.find_or_create_by(value: option[:value])
          product.sizes |= [attributes[:size]]
        when "Version", "Edition", "Variante", "Variants"
          attributes[:version] = Version.find_or_create_by(value: option[:value])
          product.versions |= [attributes[:version]]
        end
      end

      attributes
    end

    def update_shopify_store_info!
      store_info = edition.shopify_info || edition.store_infos.shopify.new

      store_info.assign_attributes(
        store_id: parsed[:shopify_id],
        pull_time: Time.zone.now,
        ext_created_at: parsed.dig(:store_info, :ext_created_at),
        ext_updated_at: parsed.dig(:store_info, :ext_updated_at)
      )

      store_info.save!
    end
  end
end
