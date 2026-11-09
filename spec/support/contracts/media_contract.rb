# frozen_string_literal: true

RSpec.shared_examples "valid media contract" do
  it "has a non-empty array of media items" do
    expect(parsed_media).to be_an(Array)
    expect(parsed_media).not_to be_empty
  end

  context "with a media item" do
    let(:media_item) { parsed_media.first }

    it "has required top-level keys" do
      expect(media_item).to include(:key, :id, :url, :alt, :position)
    end

    it "has integer position" do
      expect(media_item[:position]).to be_an(Integer)
    end

    it "has string url" do
      expect(media_item[:url]).to be_a(String)
    end
  end
end
