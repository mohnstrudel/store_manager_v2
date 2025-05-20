require "rails_helper"

RSpec.describe Shopify::PullSalesJob do
  let(:job) { described_class.new }

  describe "implementation details" do
    it "defines the correct resource_name" do
      expect(job.send(:resource_name)).to eq("orders")
    end

    it "uses the correct parser_class" do
      expect(job.send(:parser_class)).to eq(Shopify::SaleParser)
    end

    it "uses the correct creator_class" do
      expect(job.send(:creator_class)).to eq(Shopify::SaleCreator)
    end

    it "sets the correct batch_size" do
      expect(job.send(:batch_size)).to eq(250)
    end
  end
end
