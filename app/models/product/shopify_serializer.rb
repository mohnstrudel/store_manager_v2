# frozen_string_literal: true

class Product
  class ShopifySerializer
    attr_reader :product
    private :product

    def self.for_export(product)
      raise ArgumentError, "Product cannot be blank" if product.blank?

      new(product).serialize
    end

    def initialize(product)
      @product = product
    end

    def serialize
      {
        title: build_title,
        descriptionHtml: build_description_html
      }.compact
    end

    private

    def build_title
      franchise = product.franchise.title
      product_name = product.title
      shape = product.shape.title
      brand = product.brands.pluck(:title).join(", ")

      "#{franchise} - #{product_name} | Resin #{shape} | by #{brand}"
    end

    def build_description_html
      return nil if product.description.body.blank?

      product.description.body.to_html.strip
    end
  end
end
