# frozen_string_literal: true

class Product
  class ShopifyImporter
    attr_reader :parsed, :product
    private :parsed, :product

    def self.import!(parsed_payload)
      raise ArgumentError, "Parsed payload cannot be blank" if parsed_payload.blank?

      new(parsed_payload).update_or_create!
    end

    def initialize(parsed_payload)
      @parsed = parsed_payload
    end

    def update_or_create!
      update_or_create_product!

      if parsed[:store_id]
        update_shopify_store_info!
      end

      if parsed[:editions]
        Shopify::PullEditionsJob.perform_later(product, parsed[:editions])
      end

      if parsed[:media]
        Shopify::PullMediaJob.perform_later(product.id, parsed[:media])
      end

      product
    end

    private

    def update_or_create_product!
      ActiveRecord::Base.transaction do
        find_or_initialize_product
        product.assign_attributes(
          title: parsed[:title],
          franchise: Franchise.find_or_create_by(title: parsed[:franchise]),
          shape: Shape.find_or_create_by(title: parsed[:shape]),
          sku: parsed[:sku]
        )
        assign_brand
        assign_size
        assign_full_title
        product.save!
      end
    end

    def find_or_initialize_product
      if parsed[:store_id]
        @product = Product.find_by_shopify_id(parsed[:store_id])
      end

      if product.nil? && parsed[:store_link].present?
        @product = find_by_store_link
      end

      @product ||= Product.new
    end

    def find_by_store_link
      store_info = StoreInfo.find_by(store_name: :shopify, slug: parsed[:store_link])
      store_info&.storable
    end

    def assign_full_title
      title_part = build_title_part
      brand_part = parsed[:brand]

      product.full_title = [title_part, brand_part].compact_blank.join(" | ")
    end

    def build_title_part
      if product.title == product.franchise.title
        product.title
      else
        "#{product.franchise.title} — #{product.title}"
      end
    end

    def update_shopify_store_info!
      store_info = product.shopify_info || product.store_infos.shopify.new

      store_info.assign_attributes(
        store_id: parsed[:store_id],
        slug: parsed[:store_link],
        pull_time: Time.zone.now,
        ext_created_at: parsed.dig(:store_info, :ext_created_at),
        ext_updated_at: parsed.dig(:store_info, :ext_updated_at),
        tag_list: parsed[:tags]
      )

      store_info.save!
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
  end
end
