# frozen_string_literal: true

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

    it "returns only title in serialized output when description is blank" do
      serializer = described_class.new(product)
      result = serializer.serialize

      expect(result.keys).to eq([:title])
    end

    it "includes descriptionHtml when product has description", :aggregate_failures do
      html_description = "<p>This is a <strong>premium</strong> collectible figure.</p>"
      product.update(description: html_description)

      result = described_class.serialize(product)

      expect(result.keys).to eq([:title, :descriptionHtml])
      expect(result[:descriptionHtml]).to eq(html_description)
    end

    it "does not include descriptionHtml when description is nil" do
      result = described_class.serialize(product)

      expect(result.key?(:descriptionHtml)).to be false
    end

    it "does not include descriptionHtml when description is empty string" do
      product.update(description: "")

      result = described_class.serialize(product)

      expect(result.key?(:descriptionHtml)).to be false
    end

    it "returns title as a string" do
      serializer = described_class.new(product)
      result = serializer.serialize

      expect(result[:title]).to be_a(String)
    end

    it "handles multiple brands" do
      second_brand = create(:brand, title: "Another Studio")
      product.brands << second_brand

      result = described_class.serialize(product)

      expect(result[:title]).to include("by Zuoban Studio, Another Studio")
    end
  end
end
