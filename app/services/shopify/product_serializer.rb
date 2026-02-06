# frozen_string_literal: true

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

    serialized = {
      title: "#{franchise} - #{product} | Resin #{shape} | by #{brand}"
    }

    serialized[:descriptionHtml] = @product.description.body.to_html.strip if @product.description.body.present?

    serialized
  end
end
