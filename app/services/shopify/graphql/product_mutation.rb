# frozen_string_literal: true

module Shopify
  module Graphql
    class ProductMutation
      def self.create(serialized_product)
        <<~GQL
          mutation {
            productCreate(product: #{serialized_product}) {
              product {
                id
                title
                handle
              }
              userErrors {
                field
                message
              }
            }
          }
        GQL
      end

      def self.update
        <<~GQL
          mutation productUpdate($product: ProductUpdateInput!) {
            productUpdate(product: $product) {
              product {
                id
                title
                handle
                media(first: 20) {
                  nodes {
                    id
                  }
                }
              }
              userErrors {
                field
                message
              }
            }
          }
        GQL
      end

      def self.create_options
        <<~GQL
          mutation createOptions($productId: ID!, $options: [OptionCreateInput!]!, $variantStrategy: ProductOptionCreateVariantStrategy) {
            productOptionsCreate(productId: $productId, options: $options, variantStrategy: $variantStrategy) {
              userErrors {
                field
                message
              }
              product {
                id
                variants(first: 10) {
                  nodes {
                    id
                    title
                    selectedOptions {
                      name
                      value
                    }
                  }
                }
                options {
                  id
                  name
                  values
                  position
                  optionValues {
                    id
                    name
                    hasVariants
                  }
                }
              }
            }
          }
        GQL
      end
    end
  end
end
