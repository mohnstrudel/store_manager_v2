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

    it "includes variant fields" do
      expect(described_class::PRODUCT_FIELDS).to include("variants")
      expect(described_class::PRODUCT_FIELDS).to include("sku")
      expect(described_class::PRODUCT_FIELDS).to include("selectedOptions")
    end
  end
end
