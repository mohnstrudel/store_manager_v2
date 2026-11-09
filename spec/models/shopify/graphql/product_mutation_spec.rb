# frozen_string_literal: true

RSpec.describe Shopify::Graphql::ProductMutation do
  describe ".create" do
    it "returns a valid GraphQL mutation string" do
      serialized_product = "{title: 'Test'}"
      mutation = described_class.create(serialized_product)

      expect(mutation).to include("mutation")
      expect(mutation).to include("productCreate")
      expect(mutation).to include("product: #{serialized_product}")
      expect(mutation).to include("product {")
      expect(mutation).to include("id")
      expect(mutation).to include("title")
      expect(mutation).to include("handle")
    end

    it "includes userErrors field for error handling" do
      serialized_product = "{title: 'Test'}"
      mutation = described_class.create(serialized_product)

      expect(mutation).to include("userErrors")
      expect(mutation).to include("field")
      expect(mutation).to include("message")
    end
  end

  describe ".update" do
    it "returns a valid GraphQL mutation string" do
      mutation = described_class.update

      expect(mutation).to include("mutation productUpdate")
      expect(mutation).to include("$product: ProductUpdateInput!")
      expect(mutation).to include("productUpdate(product: $product)")
    end

    it "includes media nodes in response" do
      mutation = described_class.update

      expect(mutation).to include("media")
      expect(mutation).to include("nodes")
    end

    it "requests every media a product can have" do
      expect(described_class.update).to include("media(first: 250)")
    end
  end

  describe ".create_options" do
    it "returns a valid GraphQL mutation string" do
      mutation = described_class.create_options

      expect(mutation).to include("mutation createOptions")
      expect(mutation).to include("$productId: ID!")
      expect(mutation).to include("$options: [OptionCreateInput!]")
      expect(mutation).to include("productOptionsCreate")
    end

    it "includes variantStrategy parameter" do
      mutation = described_class.create_options

      expect(mutation).to include("$variantStrategy: ProductOptionCreateVariantStrategy")
    end

    it "includes product response with variants and options" do
      mutation = described_class.create_options

      expect(mutation).to include("variants")
      expect(mutation).to include("options")
      expect(mutation).to include("optionValues")
    end

    it "requests up to 250 variants" do
      expect(described_class.create_options).to include("variants(first: 250)")
    end
  end
end
