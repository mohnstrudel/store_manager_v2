require "rails_helper"

RSpec.describe Shopify::ProductSerializer do
  describe ".serialize" do
    it "calls serialize on the instance" do
      product = build(:product)
      serializer_instance = instance_double(described_class)

      allow(described_class).to receive(:new).and_return(serializer_instance)
      allow(serializer_instance).to receive(:serialize)

      described_class.serialize(product)

      expect(serializer_instance).to have_received(:serialize)
    end
  end

  describe "#serialize" do
    let(:franchise) { create(:franchise, title: "Studio Ghibli") }
    let(:shape) { create(:shape, title: "Statue") }
    let(:brand) { create(:brand, title: "Zuoban Studio") }
    let(:product) { create(:product, title: "Spirited Away", franchise: franchise, shape: shape) }

    before do
      product.brands << brand
    end

    it "serializes product title" do
      serializer = described_class.new(product)
      result = serializer.serialize

      expect(result[:title]).to eq("Studio Ghibli - Spirited Away | Resin Statue | by Zuoban Studio")
    end

    it "serializes product without options" do
      serializer = described_class.new(product)
      result = serializer.serialize

      expect(result[:productOptions]).to eq([])
    end

    it "serializes product with options" do
      size = create(:size, value: "1:4")
      product.sizes << size

      result = described_class.serialize(product)

      expect(result[:productOptions]).to include(
        {
          name: "Size",
          values: [{name: "1:4"}]
        }
      )
    end
  end
end
