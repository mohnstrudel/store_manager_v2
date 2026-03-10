# frozen_string_literal: true

# Shared contract test to verify data structure compatibility between
# components that produce and consume parsed media data.
#
# Usage: Define `parsed_media` as a let in your spec, then:
#   it_behaves_like "valid media contract"
#
# This ensures that parsers produce output that jobs can consume.

RSpec.shared_examples "valid media contract" do
  # The including spec must define `parsed_media` as a let

  # rubocop:disable RSpec/MultipleExpectations
  it "has a non-empty array of media items" do
    expect(parsed_media).to be_an(Array)
    expect(parsed_media).not_to be_empty
  end
  # rubocop:enable RSpec/MultipleExpectations

  context "with a media item" do
    let(:media_item) { parsed_media.first }

    it "has required top-level keys" do
      expect(media_item).to include(:id, :url, :alt, :position)
    end

    it "has store_info nested structure" do
      expect(media_item).to have_key(:store_info)
      expect(media_item[:store_info]).to be_a(Hash)
    end

    it "store_info contains ext_created_at and ext_updated_at" do
      store_info = media_item[:store_info]
      expect(store_info).to have_key(:ext_created_at)
      expect(store_info).to have_key(:ext_updated_at)
    end

    it "has string or nil values for timestamps" do
      store_info = media_item[:store_info]
      expect(store_info[:ext_created_at]).to satisfy { |v| v.nil? || v.is_a?(String) }
      expect(store_info[:ext_updated_at]).to satisfy { |v| v.nil? || v.is_a?(String) }
    end

    it "has integer position" do
      expect(media_item[:position]).to be_an(Integer)
    end

    it "has string url" do
      expect(media_item[:url]).to be_a(String)
    end
  end
end
