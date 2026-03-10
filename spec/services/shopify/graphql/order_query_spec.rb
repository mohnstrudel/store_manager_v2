# frozen_string_literal: true

RSpec.describe Shopify::Graphql::OrderQuery do
  describe ".by_id" do
    it "returns a valid GraphQL query string" do
      query = described_class.by_id

      expect(query).to include("query")
      expect(query).to include("order(id: $id)")
      expect(query).to include("id")
      expect(query).to include("name")
    end

    it "includes SALE_FIELDS constant content" do
      query = described_class.by_id

      expect(query).to include("customer")
      expect(query).to include("lineItems")
      expect(query).to include("shippingAddress")
    end
  end

  describe ".list" do
    it "returns a valid GraphQL query string" do
      query = described_class.list

      expect(query).to include("query")
      expect(query).to include("orders(")
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

  describe "SALE_FIELDS" do
    it "includes required order fields" do
      expect(described_class::SALE_FIELDS).to include("id")
      expect(described_class::SALE_FIELDS).to include("name")
      expect(described_class::SALE_FIELDS).to include("totalPrice")
      expect(described_class::SALE_FIELDS).to include("createdAt")
    end

    it "includes customer fields" do
      expect(described_class::SALE_FIELDS).to include("customer")
      expect(described_class::SALE_FIELDS).to include("email")
      expect(described_class::SALE_FIELDS).to include("firstName")
      expect(described_class::SALE_FIELDS).to include("lastName")
    end

    it "includes shipping address fields" do
      expect(described_class::SALE_FIELDS).to include("shippingAddress")
      expect(described_class::SALE_FIELDS).to include("address1")
      expect(described_class::SALE_FIELDS).to include("city")
      expect(described_class::SALE_FIELDS).to include("zip")
    end

    it "includes line items fields" do
      expect(described_class::SALE_FIELDS).to include("lineItems")
      expect(described_class::SALE_FIELDS).to include("quantity")
      expect(described_class::SALE_FIELDS).to include("variantTitle")
    end

    it "includes product fields from ProductQuery" do
      expect(described_class::SALE_FIELDS).to include("id")
      expect(described_class::SALE_FIELDS).to include("title")
      expect(described_class::SALE_FIELDS).to include("handle")
      expect(described_class::SALE_FIELDS).to include("createdAt")
    end
  end
end
