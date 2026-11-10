# frozen_string_literal: true

module Shopify
  module Graphql
    module ListArguments
      def self.for(updated_since:)
        return "sortKey: CREATED_AT, reverse: true" unless updated_since

        %(query: "updated_at:>='#{updated_since.getutc.iso8601}'", sortKey: UPDATED_AT)
      end
    end
  end
end
