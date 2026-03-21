# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe ".for_media_sync" do
    it "preloads media attachments and shopify info" do
      relation = described_class.for_media_sync

      expect(relation).to be_a(ActiveRecord::Relation)
      expect(relation.includes_values).to eq([
        {
          media: [:image_attachment, :image_blob, :shopify_info]
        }
      ])
    end
  end
end
