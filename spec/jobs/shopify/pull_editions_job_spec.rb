require "rails_helper"

RSpec.describe Shopify::PullEditionsJob do
  let(:job) { described_class.new }
  let(:product) { create(:product) }
  let(:parsed_editions) do
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
    it "processes each edition using EditionCreator" do
      edition_creator_class_double = class_double(Shopify::EditionCreator)
      edition_creator_instance_double = instance_double(Shopify::EditionCreator)

      stub_const("Shopify::EditionCreator", edition_creator_class_double)

      allow(edition_creator_class_double).to receive(:new)
        .with(product, parsed_editions.first)
        .and_return(edition_creator_instance_double)
      allow(edition_creator_instance_double).to receive(:update_or_create!)

      job.perform(product, parsed_editions)

      expect(edition_creator_class_double).to have_received(:new)
      expect(edition_creator_instance_double).to have_received(:update_or_create!)
    end
  end
end
