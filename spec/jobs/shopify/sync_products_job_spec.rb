require "rails_helper"

RSpec.describe Shopify::SyncProductsJob do
  let(:job) { described_class.new }

  describe "implementation details" do
    it "defines the correct resource_name" do
      expect(job.send(:resource_name)).to eq("products")
    end

    it "uses the correct parser_class" do
      expect(job.send(:parser_class)).to eq(Shopify::ProductParser)
    end

    it "uses the correct creator_class" do
      expect(job.send(:creator_class)).to eq(Shopify::ProductCreator)
    end

    it "sets the correct batch_size" do
      expect(job.send(:batch_size)).to eq(250)
    end

    it "defines the correct GraphQL query" do
      query = job.send(:query)

      # Check for essential parts of the query
      expect(query).to include("query($first: Int!, $after: String)")
      expect(query).to include("products(")
      expect(query).to include("first: $first")
      expect(query).to include("after: $after")
      expect(query).to include("sortKey: CREATED_AT")
      expect(query).to include("reverse: true")
      expect(query).to include("hasNextPage")
      expect(query).to include("endCursor")
    end
  end
end
