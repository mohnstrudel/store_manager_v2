require "rails_helper"

RSpec.describe StoreInfo, type: :model do
  describe ".find_or_create_option" do
    let(:product_size) { create(:product_size) }

    it "finds existing store info" do
      existing_store_info = create(:store_info, storable: product_size, name: :shopify)

      result = described_class.find_or_create_option(product_size, store_name: :shopify)

      expect(result).to eq(existing_store_info)
      expect(result).to be_persisted
    end

    it "creates new store info if not exists" do
      result = described_class.find_or_create_option(product_size, store_name: :shopify)

      expect(result).to be_new_record
      expect(result.storable).to eq(product_size)
      expect(result.name).to eq("shopify")
    end
  end

  describe "#option_value" do
    context "when storable is ProductSize" do
      let(:size) { create(:size, value: "Large") }
      let(:product_size) { create(:product_size, size: size) }
      let(:store_info) { create(:store_info, storable: product_size) }

      it "returns size value" do
        expect(store_info.option_value).to eq("Large")
      end
    end

    context "when storable is ProductVersion" do
      let(:version) { create(:version, value: "2.0") }
      let(:product_version) { create(:product_version, version: version) }
      let(:store_info) { create(:store_info, storable: product_version) }

      it "returns version value" do
        expect(store_info.option_value).to eq("2.0")
      end
    end

    context "when storable is ProductColor" do
      let(:color) { create(:color, value: "Blue") }
      let(:product_color) { create(:product_color, color: color) }
      let(:store_info) { create(:store_info, storable: product_color) }

      it "returns color value" do
        expect(store_info.option_value).to eq("Blue")
      end
    end

    context "when associated value is nil" do
      let(:product_size) { create(:product_size, size: nil) }
      let(:store_info) { create(:store_info, storable: product_size) }

      it "returns nil" do
        expect(store_info.option_value).to be_nil
      end
    end
  end

  describe "#option_type" do
    context "when storable is ProductSize" do
      let(:product_size) { create(:product_size) }
      let(:store_info) { create(:store_info, storable: product_size) }

      it "returns 'Size'" do
        expect(store_info.option_type).to eq("Size")
      end
    end

    context "when storable is ProductVersion" do
      let(:product_version) { create(:product_version) }
      let(:store_info) { create(:store_info, storable: product_version) }

      it "returns 'Version'" do
        expect(store_info.option_type).to eq("Version")
      end
    end

    context "when storable is ProductColor" do
      let(:product_color) { create(:product_color) }
      let(:store_info) { create(:store_info, storable: product_color) }

      it "returns 'Color'" do
        expect(store_info.option_type).to eq("Color")
      end
    end

    context "when storable type is unknown" do
      let(:product) { create(:product) }
      let(:store_info) { create(:store_info, storable: product) }

      it "returns storable_type" do
        expect(store_info.option_type).to eq("Product")
      end
    end
  end
end
