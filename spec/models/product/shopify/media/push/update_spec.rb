# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product::Shopify::Media::Push::Update do
  include ActiveSupport::Testing::TimeHelpers

  let(:product) { create(:product_with_brands) }
  let(:api_client) { instance_spy(Shopify::Api::Client) }
  let(:store_id) { "gid://shopify/MediaImage/789" }
  let(:media) { create(:media, mediaable: product, alt: "Updated Alt") }
  let(:blob) { media.image.blob }
  let(:stored_checksum) { blob.checksum }
  let(:stored_alt) { "Updated Alt" }
  let(:file_in_storage) { true }
  let!(:shopify_info) do
    create(:store_info, :shopify,
      storable: media,
      store_id:,
      checksum: stored_checksum,
      alt_text: stored_alt)
  end
  let(:updated_shopify_media) do
    [
      {"id" => store_id, "createdAt" => "2024-01-10T10:00:00Z", "updatedAt" => "2024-01-15T11:00:00Z"}
    ]
  end

  def update(*existing_media)
    described_class.new(product:, api_client:, existing_media: existing_media.map(&:reload)).call
  end

  before do
    ActiveStorage::Current.url_options = {host: "example.com"}
    allow(blob.service).to receive(:exist?).with(blob.key).and_return(file_in_storage)
    allow(api_client).to receive(:update_media).and_return(updated_shopify_media)
  end

  context "when both the alt and the checksum differ from the store info" do
    let(:stored_checksum) { "old_checksum" }
    let(:stored_alt) { "Old Alt" }

    it "sends the new file and alt, then syncs the store info" do
      update(media)

      expect(api_client).to have_received(:update_media).with([
        {id: store_id, alt: "Updated Alt", originalSource: kind_of(String)}
      ])
      expect(shopify_info.reload).to have_attributes(
        checksum: blob.checksum,
        alt_text: "Updated Alt",
        ext_created_at: Time.zone.parse("2024-01-10T10:00:00Z"),
        ext_updated_at: Time.zone.parse("2024-01-15T11:00:00Z"),
        push_time: be_present
      )
    end
  end

  context "when only the checksum differs" do
    let(:stored_checksum) { "old_checksum" }

    it "sends the new file after checking that it is in storage" do
      update(media)

      expect(blob.service).to have_received(:exist?).with(blob.key)
      expect(api_client).to have_received(:update_media).with([
        {id: store_id, alt: "Updated Alt", originalSource: kind_of(String)}
      ])
      expect(shopify_info.reload.checksum).to eq(blob.checksum)
    end

    context "when the file is not in storage yet" do
      let(:file_in_storage) { false }

      it "raises NotReady before any Shopify call and leaves the store info alone" do
        expect { update(media) }.to raise_error(Product::Shopify::Media::Push::NotReady)

        expect(api_client).not_to have_received(:update_media)
        expect(shopify_info.reload.checksum).to eq("old_checksum")
      end
    end
  end

  context "when only the alt differs" do
    let(:stored_alt) { "Old Alt" }

    it "sends the alt without the file and without checking storage" do
      update(media)

      expect(api_client).to have_received(:update_media).with([{id: store_id, alt: "Updated Alt"}])
      expect(blob.service).not_to have_received(:exist?)
      expect(shopify_info.reload).to have_attributes(alt_text: "Updated Alt", checksum: blob.checksum, push_time: be_present)
    end

    context "when the file is not in storage" do
      let(:file_in_storage) { false }

      it "still sends the alt" do
        update(media)

        expect(api_client).to have_received(:update_media).with([{id: store_id, alt: "Updated Alt"}])
      end
    end
  end

  context "when the alt is cleared" do
    let(:media) { create(:media, mediaable: product, alt: "") }
    let(:stored_alt) { "Old Alt" }

    it "sends the product title as the alt" do
      update(media)

      expect(api_client).to have_received(:update_media).with([{id: store_id, alt: "#{product.title} image"}])
    end
  end

  context "when nothing differs from the store info" do
    it "sends no fileUpdate and leaves the store info alone" do
      expect { update(media) }.not_to change { shopify_info.reload.attributes }

      expect(api_client).not_to have_received(:update_media)
      expect(blob.service).not_to have_received(:exist?)
    end
  end

  context "when the media alt is blank and the stored alt is nil" do
    let(:media) { create(:media, mediaable: product, alt: "") }
    let(:stored_alt) { nil }

    it "sends no fileUpdate" do
      update(media)

      expect(api_client).not_to have_received(:update_media)
    end
  end

  context "when only some of the media changed" do
    let(:other_media) { create(:media, mediaable: product, alt: "Other") }
    let!(:other_info) do
      create(:store_info, :shopify,
        storable: other_media,
        store_id: "gid://shopify/MediaImage/790",
        checksum: other_media.image.blob.checksum,
        alt_text: "Other")
    end
    let(:stored_alt) { "Old Alt" }

    it "sends only the changed media" do
      update(media, other_media)

      expect(api_client).to have_received(:update_media).with([{id: store_id, alt: "Updated Alt"}])
      expect(other_info.reload.push_time).to be_nil
    end
  end
end
