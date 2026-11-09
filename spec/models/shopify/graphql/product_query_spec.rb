# frozen_string_literal: true

require "rails_helper"

RSpec.describe Shopify::Graphql::ProductQuery do
  describe ".by_id" do
    it "returns a valid GraphQL query string" do
      query = described_class.by_id

      expect(query).to include("query ProductById")
      expect(query).to include("product(id: $id)")
      expect(query).to include("id")
      expect(query).to include("title")
      expect(query).to include("handle")
    end

    it "includes PRODUCT_FIELDS constant content" do
      query = described_class.by_id

      expect(query).to include("media")
      expect(query).to include("variants")
      expect(query).to include("edges")
    end

    it "requests every media a product can have and up to 250 variants" do
      query = described_class.by_id

      aggregate_failures do
        expect(query).to include("media(first: 250)")
        expect(query).to include("variants(first: 250)")
      end
    end

    it "asks whether variants were truncated" do
      expect(described_class.by_id).to match(
        /variants\(first: 250\) \{\s*pageInfo \{\s*hasNextPage\s*\}\s*edges \{\s*node \{/
      )
    end
  end

  describe ".list" do
    it "returns a valid GraphQL query string" do
      query = described_class.list

      expect(query).to include("query FetchProducts")
      expect(query).to include("products(")
      expect(query).to include("$first: Int!")
      expect(query).to include("$after: String")
    end

    it "includes pagination fields" do
      query = described_class.list

      expect(query).to include("pageInfo")
      expect(query).to include("hasNextPage")
      expect(query).to include("endCursor")
    end

    it "requests every media a product can have and up to 100 variants" do
      query = described_class.list

      aggregate_failures do
        expect(query).to include("media(first: 250)")
        expect(query).to include("variants(first: 100)")
        expect(query).not_to include("variants(first: 250)")
      end
    end

    it "asks whether variants were truncated" do
      expect(described_class.list).to match(
        /variants\(first: 100\) \{\s*pageInfo \{\s*hasNextPage\s*\}\s*edges \{\s*node \{/
      )
    end
  end

  describe "PRODUCT_FIELDS" do
    it "includes required product fields" do
      expect(described_class::PRODUCT_FIELDS).to include("id")
      expect(described_class::PRODUCT_FIELDS).to include("title")
      expect(described_class::PRODUCT_FIELDS).to include("handle")
      expect(described_class::PRODUCT_FIELDS).to include("tags")
      expect(described_class::PRODUCT_FIELDS).to include("createdAt")
      expect(described_class::PRODUCT_FIELDS).to include("updatedAt")
    end

    it "includes media fields" do
      expect(described_class::PRODUCT_FIELDS).to include("media")
      expect(described_class::PRODUCT_FIELDS).to include("MediaImage")
    end

    it "leaves the variants connection to each query" do
      expect(described_class::PRODUCT_FIELDS).not_to include("variants")
    end
  end

  describe "VARIANT_CONNECTION_FIELDS" do
    it "includes variant fields" do
      expect(described_class::VARIANT_CONNECTION_FIELDS).to include("sku")
      expect(described_class::VARIANT_CONNECTION_FIELDS).to include("selectedOptions")
    end
  end
end
