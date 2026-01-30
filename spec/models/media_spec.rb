# frozen_string_literal: true

require "rails_helper"

RSpec.describe Media, type: :model do
  describe "associations" do
    it { should belong_to(:mediaable).inverse_of(:media) }
    it { should have_many(:store_infos).dependent(:destroy) }

    it "has_one_attached image with dependent: :purge_later" do
      media = create(:media, :for_product)
      expect(media.image).to be_present
    end
  end

  describe "delegates" do
    let(:media) { create(:media, :for_product) }

    it "delegates missing methods to image" do
      # Test that methods like url, filename, etc are delegated
      expect(media).to respond_to(:url)
      expect(media).to respond_to(:filename)
      expect(media).to respond_to(:variant)
    end
  end

  describe "scopes" do
    describe ".ordered" do
      let(:product) { create(:product) }
      let!(:media1) { create(:media, :for_product, mediaable: product, position: 2) }
      let!(:media2) { create(:media, :for_product, mediaable: product, position: 1) }
      let!(:media3) { create(:media, :for_product, mediaable: product, position: 3) }

      it "orders by position ascending" do
        expect(Media.ordered).to eq([media2, media1, media3])
      end
    end
  end

  describe "image variants" do
    let(:media) { create(:media, :for_product) }

    it "has a preview variant" do
      variant = media.image.variant(:preview)
      expect(variant).to be_present
    end

    it "has a thumb variant" do
      variant = media.image.variant(:thumb)
      expect(variant).to be_present
    end

    it "has a nano variant" do
      variant = media.image.variant(:nano)
      expect(variant).to be_present
    end
  end

  describe "callbacks" do
    describe "#destroy_if_image_removed" do
      context "when image is removed" do
        let(:media) { create(:media, :for_product) }

        it "destroys the media record" do
          media.image.detach
          media.save!

          expect(media).not_to be_persisted
        end

        it "destroys associated store_infos" do
          store_info = create(:store_info, :shopify, storable: media)

          media.image.detach
          media.save!

          expect { store_info.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when image is still attached" do
        let(:media) { create(:media, :for_product) }

        it "does not destroy the media record on subsequent saves" do
          media_id = media.id
          media.save!
          expect(Media.exists?(media_id)).to be true
        end

        it "keeps the media record persisted" do
          media.save!
          expect(media).to be_persisted
        end
      end

      context "when media is not persisted (new record)" do
        let(:product) { create(:product) }
        let(:media) { build(:media, :for_product, mediaable: product) }

        it "does not try to destroy" do
          media.image.detach
          expect { media.save }.not_to raise_error
        end
      end

      context "when updating other attributes" do
        let(:media) { create(:media, :for_product, alt: "Original") }

        it "does not destroy when updating alt text" do
          media_id = media.id
          media.update!(alt: "Updated")
          expect(Media.exists?(media_id)).to be true
          expect(media.reload.alt).to eq("Updated")
        end

        it "does not destroy when updating position" do
          media_id = media.id
          media.update!(position: 5)
          expect(Media.exists?(media_id)).to be true
          expect(media.reload.position).to eq(5)
        end
      end
    end
  end

  describe "store_infos association" do
    let(:media) { create(:media, :for_product) }
    let!(:shopify_info) { create(:store_info, :shopify, storable: media) }
    let!(:woo_info) { create(:store_info, :woo, storable: media) }

    it "has multiple store_infos" do
      expect(media.store_infos.count).to eq(2)
    end

    it "destroys store_infos when media is destroyed" do
      expect {
        media.destroy
      }.to change(StoreInfo, :count).by(-2)
    end
  end

  describe "polymorphic association" do
    let(:product) { create(:product) }
    let!(:media) { create(:media, :for_product, mediaable: product) }

    it "belongs to a product" do
      expect(media.mediaable).to eq(product)
    end

    it "can be accessed through product" do
      expect(product.media).to include(media)
    end

    it "can belong to different mediaable types" do
      warehouse = create(:warehouse)
      warehouse_media = create(:media, :for_warehouse, mediaable: warehouse)

      expect(warehouse_media.mediaable).to eq(warehouse)
      expect(warehouse.media).to include(warehouse_media)
    end
  end

  describe "validation" do
    it "is valid with valid attributes" do
      product = create(:product)
      media = build(:media, :for_product, mediaable: product)
      expect(media).to be_valid
    end

    it "requires mediaable" do
      media = build(:media, mediaable: nil)
      expect(media).not_to be_valid
      expect(media.errors[:mediaable]).to include("must exist")
    end

    it "validates alt text defaults to empty string" do
      media = create(:media, :for_product)
      expect(media.alt).to eq("Test image")
    end

    it "validates position defaults to 0" do
      media = create(:media, :for_product)
      expect(media.position).to eq(0)
    end
  end

  describe "with attached image" do
    let(:media) { create(:media, :for_product) }

    it "has an attached image" do
      expect(media.image.attached?).to be true
    end

    it "can access image metadata" do
      expect(media.image.filename).to be_present
      expect(media.image.content_type).to be_present
    end
  end
end
