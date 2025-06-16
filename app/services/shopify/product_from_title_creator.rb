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
    attrs = {
      title: product_title,
      franchise: Franchise.find_or_create_by(
        title: franchise_title
      ),
      shape: Shape.find_or_create_by(
        title: shape_title
      )
    }
    @product = Product.find_or_create_by(attrs)
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
