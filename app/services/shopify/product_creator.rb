class Shopify::ProductCreator
  def initialize(parsed_product: {}, parsed_title: "")
    @parsed_product = parsed_product
    @parsed_title = parsed_title
  end

  def update_or_create!
    return if @parsed_product.blank?

    product = ActiveRecord::Base.transaction do
      find_or_initialize_product
      update_product_attributes
      assign_brand
      assign_size
      update_full_title
      @product.save!
      @product
    end

    if product
      Shopify::PullVariationsJob.perform_later(
        product,
        @parsed_product[:variations]
      )
      Shopify::PullImagesJob.perform_later(
        product,
        @parsed_product[:images]
      )
    end

    product
  end

  def update_or_create_by_title
    title, franchise, size, shape, brand_title = Shopify::ProductParser.new(title: @parsed_title).parse_product_title

    core_attributes = build_core_attributes(title, franchise, shape)

    @product = Product.find_or_create_by(core_attributes)

    assign_size(size) if size
    assign_brand(brand_title) if brand_title

    @product
  end

  private

  def find_or_initialize_product
    existing_product = Product.find_by(shopify_id: @parsed_product[:shopify_id])

    @product = if existing_product
      existing_product
    elsif brand
      brand.products.find_or_initialize_by(build_core_attributes)
    else
      Product.find_or_initialize_by(build_core_attributes)
    end
  end

  def build_core_attributes(title = nil, franchise = nil, shape = nil)
    @core_attributes ||= {
      title: title || @parsed_product[:title],
      franchise: Franchise.find_or_create_by(
        title: franchise || @parsed_product[:franchise]
      ),
      shape: Shape.find_or_create_by(
        title: shape || @parsed_product[:shape]
      )
    }
  end

  def update_product_attributes
    @product.assign_attributes(
      shopify_id: @parsed_product[:shopify_id],
      store_link: @parsed_product[:store_link],
      **build_core_attributes
    )
  end

  def assign_brand(parsed_brand = nil)
    parsed_brand ||= @parsed_product[:brand]

    if parsed_brand && !@product.brands.exists?(
      title: parsed_brand
    )
      @product.brands << brand(parsed_brand)
    end
  end

  def assign_size(parsed_size = nil)
    parsed_size ||= @parsed_product[:size]

    if parsed_size && !@product.sizes.exists?(
      value: parsed_size
    )
      @product.sizes << Size.find_or_create_by(value: parsed_size)
    end
  end

  def brand(brand_title = nil)
    parsed_brand = brand_title || @parsed_product[:brand]

    @brand ||= if parsed_brand.present?
      Brand.find_or_create_by(title: parsed_brand)
    end
  end

  def update_full_title
    @product.full_title = Product.generate_full_title(@product, brand)
  end
end
