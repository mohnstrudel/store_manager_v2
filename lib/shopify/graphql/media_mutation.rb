# frozen_string_literal: true

# Shopify::Graphql::MediaMutation
#
# GraphQL mutations and queries for managing product media in Shopify.
# Provides mutations for attaching, updating, and reordering media.
#
module Shopify
  module Graphql
    class MediaMutation
      # Mutation for attaching media to a product
      #
      # @return [String] The GraphQL mutation string
      def self.attach
        <<~GQL
          mutation($product: ProductUpdateInput!, $media: [CreateMediaInput!]) {
            productUpdate(product: $product, media: $media) {
              product {
                id
                media(first: 20) {
                  nodes {
                    ... on MediaImage {
                      id
                      alt
                      status
                      fileStatus
                      createdAt
                      updatedAt
                    }
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

      # Query for fetching the status of a media item
      # Used to check if media has finished processing
      #
      # @return [String] The GraphQL query string
      def self.status_query
        <<~GQL
          query($id: ID!) {
            node(id: $id) {
              ... on MediaImage {
                id
                status
                fileStatus
              }
            }
          }
        GQL
      end

      # Mutation for updating media attributes (e.g., alt text)
      #
      # @return [String] The GraphQL mutation string
      def self.update
        <<~GQL
          mutation($files: [FileUpdateInput!]!) {
            fileUpdate(files: $files) {
              files {
                ... on MediaImage {
                  id
                  alt
                  createdAt
                  updatedAt
                  image {
                    url
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

      # Mutation for reordering media on a product
      #
      # @return [String] The GraphQL mutation string
      def self.reorder
        <<~GQL
          mutation($id: ID!, $moves: [MoveInput!]!) {
            productReorderMedia(id: $id, moves: $moves) {
              job {
                id
                done
              }
              mediaUserErrors {
                field
                message
              }
            }
          }
        GQL
      end
    end
  end
end
