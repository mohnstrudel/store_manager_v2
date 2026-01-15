# frozen_string_literal: true

class Shopify::ProductFromTitleCreator
  def initialize(api_title: "")
    @api_title = api_title
  end

  def call
    product_title, franchise_title, size_value, shape_title, brand_title =
      Shopify::ProductParser.new(title: @api_title).parse_product_title

    find_or_create_product(product_title, franchise_title, shape_title)
    assign_relation("sizes", size_value)
    assign_relation("brands", brand_title)

    @product
  end

  private

  def find_or_create_product(product_title, franchise_title, shape_title)
    franchise = Franchise.find_or_create_by(title: franchise_title)
    shape = Shape.find_or_create_by(title: shape_title)

    @product = Product.find_or_initialize_by(
      title: product_title,
      franchise:,
      shape:
    )

    generate_sku if @product.new_record?
    @product.save! if @product.new_record?
  end

  def generate_sku
    return if @product.sku.present?

    full_title = build_full_title_for_sku
    sku = full_title.parameterize

    counter = 1
    while Product.where.not(id: @product.id).exists?(sku:)
      sku = "#{base_sku}-#{counter}"
      counter += 1
    end

    @product.sku = sku
  end

  def build_full_title_for_sku
    # We don't have brand info yet, so just use franchise and title
    if @product.title == @product.franchise.title
      @product.title
    else
      "#{@product.franchise.title} — #{@product.title}"
    end
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
end
