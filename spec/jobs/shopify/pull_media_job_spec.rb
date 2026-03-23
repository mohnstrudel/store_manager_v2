# frozen_string_literal: true

require "rails_helper"
require "support/contracts/media_contract"

RSpec.describe Shopify::PullMediaJob do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  subject(:job) { described_class.new }

  let(:product) { create(:product) }
  let(:shopify_image_id) { "gid://shopify/ProductImage/123456789" }
  let(:img_url) { "https://example.com/image.jpg" }
  let(:alt_text) { "Beautiful product photo" }
  let(:position) { 3 }
  let(:ext_created_at) { 2.days.ago.iso8601 }
  let(:ext_updated_at) { 1.hour.ago.iso8601 }

  let(:parsed_media_item) do
    {
      id: shopify_image_id,
      url: img_url,
      alt: alt_text,
      position: position,
      store_info: {
        ext_created_at: ext_created_at,
        ext_updated_at: ext_updated_at
      }
    }
  end

  let(:parsed_media) { [parsed_media_item] }

  let(:test_image_content) { "fake jpeg binary content" }
  let(:test_checksum) { Digest::MD5.base64digest(test_image_content) }
  let(:test_filename) { "product-image.jpg" }

  let(:temp_file_path) { Rails.root.join("tmp", "test_image_#{SecureRandom.hex(6)}.jpg") }

  before do
    File.write(temp_file_path, test_image_content)

    # Stub Down.download to return a tempfile with original_filename method
    temp_file = Tempfile.new(["test_", ".jpg"], Rails.root.join("tmp"))
    temp_file.write(test_image_content)
    temp_file.rewind
    # Add original_filename method to mimic Down's behavior
    filename_value = test_filename
    temp_file.define_singleton_method(:original_filename) do
      filename_value
    end
    allow(Down).to receive(:download).with(img_url, anything).and_return(temp_file)
  end

  after do
    FileUtils.rm_f(temp_file_path) if File.exist?(temp_file_path)
  end

  describe "queue" do
    it { expect(described_class.new.queue_name).to eq "default" }
  end

  # Contract test: ensure test data structure matches expectations
  describe "media contract" do
    let(:parsed_media) do
      [{
        id: shopify_image_id,
        url: img_url,
        alt: alt_text,
        position: position,
        store_info: {
          ext_created_at: ext_created_at,
          ext_updated_at: ext_updated_at
        }
      }]
    end

    it_behaves_like "valid media contract"
  end

  describe "#perform" do
    it "delegates to Product::Shopify::Media::Pull" do
      allow(Product::Shopify::Media::Pull).to receive(:call)

      job.perform(product.id, parsed_media)

      expect(Product::Shopify::Media::Pull).to have_received(:call).with(product_id: product.id, parsed_media:)
    end

    context "when product is missing" do
      it "returns early without any action" do
        expect { job.perform(nil, parsed_media) }
          .not_to change(Media, :count)
      end
    end

    context "when parsed_media is empty" do
      it "removes all local media" do
        media = create_list(:media, 2, mediaable: product)
        create(:store_info, :shopify, storable: media.first)

        expect { job.perform(product.id, []) }
          .to change { product.media.count }.from(2).to(0)
      end

      it "removes associated store_infos" do
        media = create_list(:media, 2, mediaable: product)
        create(:store_info, :shopify, storable: media.first)

        expect { job.perform(product.id, []) }
          .to change { StoreInfo.where(storable_type: "Media").count }.by(-1)
      end
    end

    context "when creating a new image" do
      # rubocop:disable RSpec/MultipleExpectations
      it "creates media + attachment + store_info" do
        freeze_time do
          expect { job.perform(product.id, parsed_media) }
            .to change { product.media.count }.by(1)
            .and change { StoreInfo.where(storable_type: "Media").count }.by(1)

          media = product.media.last
          expect(media.alt).to eq alt_text
          expect(media.position).to eq position
          expect(media.image).to be_attached
          expect(media.image.blob.checksum).to eq test_checksum

          si = media.store_infos.shopify.first
          expect(si).to be_present
          expect(si.store_id).to eq shopify_image_id
          expect(si.pull_time).to be_within(1.second).of(Time.current)
          expect(si.ext_created_at).to eq Time.zone.parse(ext_created_at)
          expect(si.ext_updated_at).to eq Time.zone.parse(ext_updated_at)
        end
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when media exists with unchanged checksum" do
      let!(:media) do
        create(:media, mediaable: product, alt: "old", position: 99)
      end
      let!(:store_info) do
        create(:store_info, :shopify,
          storable: media,
          store_id: shopify_image_id,
          checksum: test_checksum)
      end

      before do
        media.image.attach(io: File.open(temp_file_path), filename: test_filename)
      end

      it "updates media attributes and shopify_info" do
        expect { job.perform(product.id, parsed_media) }
          .to change { media.reload.alt }.to(alt_text)
          .and change { media.reload.position }.to(position)
          .and change { store_info.reload.pull_time }
      end
    end

    context "when media is reordered (checksum matches but timestamp changed)" do
      let!(:media) do
        create(:media, mediaable: product, alt: "test", position: 1)
      end
      let!(:store_info) do
        create(:store_info, :shopify,
          storable: media,
          store_id: shopify_image_id,
          ext_updated_at: 1.hour.ago, # Old timestamp
          checksum: test_checksum)
      end
      let(:new_ext_updated_at) { 5.minutes.ago.iso8601 }

      before do
        media.image.attach(io: File.open(temp_file_path), filename: test_filename)
        # Update parsed_media to have new timestamp and position (simulating reordering)
        parsed_media[0][:position] = 5
        parsed_media[0][:store_info][:ext_updated_at] = new_ext_updated_at
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "updates position without redownloading image" do
        original_checksum = media.image.blob.checksum

        job.perform(product.id, parsed_media)

        expect(media.reload.position).to eq(5)
        expect(media.image.blob.checksum).to eq(original_checksum)
      end

      it "updates timestamp without redownloading image" do
        original_checksum = media.image.blob.checksum

        job.perform(product.id, parsed_media)

        expect(store_info.reload.ext_updated_at).to eq(Time.zone.parse(new_ext_updated_at))
        expect(media.image.blob.checksum).to eq(original_checksum)
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when media exists with changed content" do
      let!(:media) { create(:media, mediaable: product) }
      # rubocop:disable RSpec/LetSetup
      let!(:store_info) do
        create(:store_info, :shopify, storable: media, store_id: shopify_image_id)
      end
      # rubocop:enable RSpec/LetSetup

      before do
        # старая картинка с другим содержимым
        media.image.attach(io: StringIO.new("old content"), filename: "old.jpg")
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "removes old media and creates new one" do
        freeze_time do
          expect { job.perform(product.id, parsed_media) }
            # rubocop:disable RSpec/ChangeByZero
            .to change { product.media.count }.by(0)
            # rubocop:enable RSpec/ChangeByZero
            .and change { Media.where(id: media.id).count }.from(1).to(0)

          new_media = product.media.ordered.last
          expect(new_media.alt).to eq alt_text
          expect(new_media.image.blob.checksum).to eq test_checksum
          expect(new_media.id).not_to eq media.id
        end
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when partial download fails" do
      let(:parsed_media) do
        [
          parsed_media_item,
          parsed_media_item.merge(id: "gid://shopify/ProductImage/999", url: "https://404.example.com")
        ]
      end

      before do
        # First URL returns a proper tempfile, second URL raises Down::Error
        temp_file = Tempfile.new(["test_", ".jpg"], Rails.root.join("tmp"))
        temp_file.write(test_image_content)
        temp_file.rewind
        filename_value = test_filename
        temp_file.define_singleton_method(:original_filename) { filename_value }

        allow(Down).to receive(:download).with(img_url, anything).and_return(temp_file)
        allow(Down).to receive(:download).with("https://404.example.com", anything)
          .and_raise(Down::Error.new("404 Not Found"))
      end

      # rubocop:disable RSpec/MultipleExpectations
      it "processes successful images and preserves failed remote media" do
        failed_remote_media = create(:media, mediaable: product)
        create(:store_info, :shopify,
          storable: failed_remote_media,
          store_id: "gid://shopify/ProductImage/999")

        job.perform(product.id, parsed_media)

        expect(Media.where(id: failed_remote_media.id)).to exist
        expect(product.media.count).to eq 2

        new_media = product.media.ordered.last
        expect(new_media.alt).to eq alt_text
        expect(new_media.image).to be_attached
      end
      # rubocop:enable RSpec/MultipleExpectations
    end

    context "when transaction rolls back on error" do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Media).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
        # rubocop:enable RSpec/AnyInstance
      end

      it "does not create partial records" do
        expect {
          begin
            job.perform(product.id, parsed_media)
          rescue
            nil
          end
        }.not_to change(Media, :count)
      end
    end
  end
end
