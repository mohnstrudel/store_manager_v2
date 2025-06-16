class Shopify::ProductCreator
  def initialize(parsed_item: {})
    raise ArgumentError, "parsed_item must be a Hash" unless parsed_item.is_a?(Hash)
    raise ArgumentError, "parsed_item cannot be blank" if parsed_item.blank?

    @parsed_product = parsed_item
  end

  def update_or_create!
    ActiveRecord::Base.transaction do
      find_or_initialize_product
      assign_relation("brands", @parsed_product[:brand])
      assign_relation("sizes", @parsed_product[:size])
      build_full_title
      @product.save!
    end

    Shopify::PullEditionsJob.perform_later(
      @product,
      @parsed_product[:editions]
    )
    Shopify::PullImagesJob.perform_later(
      @product,
      @parsed_product[:images]
    )

    @product
  end

  private

  def find_or_initialize_product
    @product = Product.find_or_initialize_by(
      shopify_id: @parsed_product[:shopify_id]
    )
    @product.assign_attributes(
      store_link: @parsed_product[:store_link],
      title: @parsed_product[:title],
      franchise: Franchise.find_or_create_by(
        title: @parsed_product[:franchise]
      ),
      shape: Shape.find_or_create_by(
        title: @parsed_product[:shape]
      )
    )
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

  def build_full_title
    @product.full_title = Product.generate_full_title(@product)
  end
end
