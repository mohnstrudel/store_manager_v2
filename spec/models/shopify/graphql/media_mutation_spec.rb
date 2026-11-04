# frozen_string_literal: true

RSpec.describe Shopify::Graphql::MediaMutation do
  describe ".attach" do
    it "returns a valid GraphQL mutation string" do
      mutation = described_class.attach

      expect(mutation).to include("mutation")
      expect(mutation).to include("productUpdate")
      expect(mutation).to include("$product: ProductUpdateInput!")
      expect(mutation).to include("$media: [CreateMediaInput!]")
    end

    it "includes media nodes in response" do
      mutation = described_class.attach

      expect(mutation).to include("media")
      expect(mutation).to include("nodes")
      expect(mutation).to include("MediaImage")
    end

    it "includes media processing status fields" do
      mutation = described_class.attach

      expect(mutation).to include("status")
      expect(mutation).to include("fileStatus")
    end
  end

  describe ".status_query" do
    it "returns a valid GraphQL query string" do
      query = described_class.status_query

      expect(query).to include("query")
      expect(query).to include("node(id: $id)")
      expect(query).to include("MediaImage")
    end

    it "includes status fields" do
      query = described_class.status_query

      expect(query).to include("status")
      expect(query).to include("fileStatus")
    end
  end

  describe ".update" do
    it "returns a valid GraphQL mutation string" do
      mutation = described_class.update

      expect(mutation).to include("mutation")
      expect(mutation).to include("fileUpdate")
      expect(mutation).to include("$files: [FileUpdateInput!]")
    end

    it "includes file response with image details" do
      mutation = described_class.update

      expect(mutation).to include("files")
      expect(mutation).to include("alt")
      expect(mutation).to include("image")
      expect(mutation).to include("url")
    end
  end

  describe ".reorder" do
    it "returns a valid GraphQL mutation string" do
      mutation = described_class.reorder

      expect(mutation).to include("mutation")
      expect(mutation).to include("productReorderMedia")
      expect(mutation).to include("$id: ID!")
      expect(mutation).to include("$moves: [MoveInput!]")
    end

    it "includes job response" do
      mutation = described_class.reorder

      expect(mutation).to include("job")
      expect(mutation).to include("id")
      expect(mutation).to include("done")
    end

    it "includes mediaUserErrors for error handling" do
      mutation = described_class.reorder

      expect(mutation).to include("mediaUserErrors")
    end
  end
end
