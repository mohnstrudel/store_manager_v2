# frozen_string_literal: true

module Shopify
  module Graphql
    class MediaMutation
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
