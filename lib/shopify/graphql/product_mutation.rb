# frozen_string_literal: true

# Shopify::Graphql::ProductMutation
#
# GraphQL mutations for products in Shopify.
# Provides mutations for product creation, updates, and option management.
#
module Shopify
  module Graphql
    class ProductMutation
      # Mutation for creating a new product
      #
      # @param serialized_product [Hash] Product data in Shopify format
      # @return [String] The GraphQL mutation string
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

      # Mutation for updating an existing product
      #
      # @return [String] The GraphQL mutation string
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

      # Mutation for creating product options (e.g., Size, Color)
      #
      # @return [String] The GraphQL mutation string
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
