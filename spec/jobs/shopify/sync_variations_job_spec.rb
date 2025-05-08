require "rails_helper"

RSpec.describe Shopify::SyncVariationsJob do
  let(:job) { described_class.new }
  let(:product) { create(:product) }
  let(:parsed_variations) do
    [
      {
        "id" => "gid://shopify/ProductVariant/12345",
        "title" => "Red / Large / Deluxe",
        "options" => [
          {"value" => "Red", "name" => "Color"},
          {"value" => "Large", "name" => "Size"},
          {"value" => "Deluxe", "name" => "Edition"}
        ]
      }
    ]
  end

  describe "#perform" do
    it "processes each variation using VariationCreator" do
      variation_creator_class_double = class_double(Shopify::VariationCreator)
      variation_creator_instance_double = instance_double(Shopify::VariationCreator)

      stub_const("Shopify::VariationCreator", variation_creator_class_double)

      allow(variation_creator_class_double).to receive(:new)
        .with(product, parsed_variations.first)
        .and_return(variation_creator_instance_double)
      allow(variation_creator_instance_double).to receive(:update_or_create!)

      job.perform(product, parsed_variations)

      expect(variation_creator_class_double).to have_received(:new)
      expect(variation_creator_instance_double).to have_received(:update_or_create!)
    end
  end
end
