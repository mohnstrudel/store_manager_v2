# frozen_string_literal: true

class Product::Shopify::Importer
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

    Shopify::PullEditionsJob.perform_later(product, parsed[:editions]) if parsed[:editions].present?
    Shopify::ImportMediaJob.perform_later(product, parsed[:media]) if parsed[:media]

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
        description: normalize_description_html(parsed[:description])
      )
      assign_brand
      assign_size
      product.full_title = product.generate_full_title
      product.build_base_edition(sku: parsed[:sku])
      product.save!

      if parsed[:store_id]
        product.upsert_shopify_info!(
          store_id: parsed[:store_id],
          slug: parsed[:store_link],
          ext_created_at: parsed.dig(:store_info, :ext_created_at),
          ext_updated_at: parsed.dig(:store_info, :ext_updated_at),
          tag_list: parsed[:tags],
          pull_time: Time.zone.now
        )
      end
    end
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

  def normalize_description_html(html)
    return html if html.blank?

    doc = Nokogiri::HTML::DocumentFragment.parse(html)
    doc.css("li > p, li > div").each do |node|
      node.add_next_sibling(node.children)
      node.remove
    end
    doc.to_html
  end
end
