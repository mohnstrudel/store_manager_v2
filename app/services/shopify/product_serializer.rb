class Shopify::ProductSerializer
  def self.serialize(*args)
    new(*args).serialize
  end

  def initialize(product)
    @product = product
  end

  def serialize
    franchise = @product.franchise.title
    product = @product.title
    shape = @product.shape.title
    brand = @product.brands.pluck(:title).join(", ")
    product_options = [
      create_option(@product.sizes),
      create_option(@product.versions),
      create_option(@product.colors)
    ].compact

    {
      title: "#{franchise} - #{product} | Resin #{shape} | by #{brand}",
      productOptions: product_options
    }
  end

  def create_option(product_attrs)
    if product_attrs.any?
      values = product_attrs.reduce([]) do |acc, el|
        acc.push({name: el.value})
      end
      {name: product_attrs.class_name, values:}
    end
  end
end
