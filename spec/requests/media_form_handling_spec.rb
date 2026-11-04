# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Media form handling" do
  before { sign_in_as_admin }

  def image_upload(filename: "test.jpg")
    Rack::Test::UploadedFile.new(
      StringIO.new("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9"),
      "image/jpeg",
      original_filename: filename
    )
  end

  def create_blob(filename: "test.jpg")
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9"),
      filename:,
      content_type: "image/jpeg"
    )
  end

  describe "POST /warehouses with new images" do
    it "attaches the images to the created warehouse in upload order", :aggregate_failures do
      expect {
        post warehouses_path, params: {
          warehouse: {
            name: "Test Warehouse",
            position: 1,
            new_images: [image_upload, image_upload(filename: "test2.jpg")]
          }
        }
      }.to change(Media, :count).by(2)

      media = Warehouse.last.media.ordered
      expect(media.count).to eq(2)
      expect(media.map(&:position)).to eq([0, 1])
    end

    it "skips non-image values", :aggregate_failures do
      expect {
        post warehouses_path, params: {
          warehouse: {
            name: "Test Warehouse",
            position: 1,
            new_images: ["not an image", nil, image_upload]
          }
        }
      }.to change(Media, :count).by(1)

      expect(Warehouse.last.media.count).to eq(1)
    end
  end

  describe "PATCH /warehouses/:id with media changes" do
    let!(:warehouse) { create(:warehouse) }
    let!(:first_media) { create(:media, :for_warehouse, mediaable: warehouse, position: 0, alt: "Original 0") }
    let!(:second_media) { create(:media, :for_warehouse, mediaable: warehouse, position: 1, alt: "Original 1") }

    def update_media(media: {}, **extra)
      patch warehouse_path(warehouse), params: {warehouse: {name: warehouse.name, media:, **extra}}
    end

    it "updates the position and alt of the submitted media only", :aggregate_failures do
      update_media(media: {"0" => {id: first_media.id.to_s, position: "5", alt: "New position and alt"}})

      expect(first_media.reload).to have_attributes(position: 5, alt: "New position and alt")
      expect(second_media.reload).to have_attributes(position: 1, alt: "Original 1")
    end

    it "updates a position without touching the alt text", :aggregate_failures do
      update_media(media: {"0" => {id: second_media.id.to_s, position: "1"}})

      expect(second_media.reload).to have_attributes(position: 1, alt: "Original 1")
    end

    it "updates alt text without touching the position", :aggregate_failures do
      update_media(media: {"0" => {id: first_media.id.to_s, alt: "Updated alt"}})

      expect(first_media.reload).to have_attributes(position: 0, alt: "Updated alt")
    end

    it "destroys media marked with _destroy 1 and keeps the rest", :aggregate_failures do
      expect {
        update_media(media: {"0" => {id: first_media.id.to_s, _destroy: "1"}})
      }.to change(warehouse.media, :count).by(-1)

      expect(Media.where(id: second_media.id)).to exist
    end

    it "keeps media marked with _destroy 0 and applies its changes", :aggregate_failures do
      expect {
        update_media(media: {"0" => {id: first_media.id.to_s, _destroy: "0", alt: "Keep this"}})
      }.not_to change(warehouse.media, :count)

      expect(first_media.reload.alt).to eq("Keep this")
    end

    it "replaces the image attachment" do
      update_media(media: {"0" => {id: first_media.id.to_s, image: image_upload(filename: "replacement.jpg")}})

      expect(first_media.reload.image.filename.to_s).to eq("replacement.jpg")
    end

    it "appends new images after the existing media", :aggregate_failures do
      update_media(new_images: [image_upload(filename: "new.jpg")])

      expect(warehouse.media.count).to eq(3)
      expect(warehouse.media.ordered.last.position).to eq(2)
    end

    it "skips media with blank ids" do
      expect {
        update_media(media: {
          "0" => {id: first_media.id.to_s, alt: "Valid"},
          "1" => {id: "", alt: "Should be skipped"},
          "2" => nil
        })
      }.not_to change(warehouse.media, :count)
    end

    it "ignores media ids that do not exist", :aggregate_failures do
      update_media(media: {"0" => {id: "999999", alt: "Non-existent"}})

      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(warehouse.media.count).to eq(2)
    end
  end

  describe "PATCH /warehouses/:id combining update, destroy, and create" do
    it "applies every change in one request", :aggregate_failures do
      warehouse = create(:warehouse)
      first_media = create(:media, :for_warehouse, mediaable: warehouse, position: 0, alt: "First")
      third_media = create(:media, :for_warehouse, mediaable: warehouse, position: 2, alt: "Third")

      expect {
        patch warehouse_path(warehouse), params: {
          warehouse: {
            name: warehouse.name,
            media: {
              "0" => {id: first_media.id.to_s, position: "2", alt: "Moved down"},
              "1" => {id: third_media.id.to_s, _destroy: "1"}
            },
            new_images: [image_upload(filename: "new.jpg")]
          }
        }
      }.not_to change(warehouse.media, :count)

      expect(first_media.reload).to have_attributes(position: 2, alt: "Moved down")
      expect(Media.where(id: third_media.id)).to be_empty
    end
  end

  describe "POST /products with media" do
    let(:franchise) { create(:franchise) }

    def product_params(title)
      {title:, franchise_id: franchise.id, shape: Product.default_shape}
    end

    it "attaches the submitted blobs at position 0", :aggregate_failures do
      existing_product = create(:product)
      create(:media, :for_product, mediaable: existing_product, position: 3)
      blobs = [create_blob, create_blob(filename: "test2.jpg")]

      expect {
        post products_path, params: {
          product: product_params("Test Product"),
          media: blobs.each_with_index.to_h { |blob, index| [index.to_s, {image_blob_id: blob.signed_id}] }
        }
      }.to change(Media, :count).by(2)

      expect(response).to have_http_status(:redirect)
      expect(Product.find_by!(title: "Test Product").media.first.position).to eq(0)
      expect(existing_product.reload.media.sole.position).to eq(3)
    end

    it "creates the product without media", :aggregate_failures do
      expect {
        post products_path, params: {product: product_params("Imageless Product")}
      }.to change(Product, :count).by(1)

      expect(response).to have_http_status(:redirect)
      expect(Product.find_by!(title: "Imageless Product").media).to be_empty
    end
  end

  describe "PATCH /products/:id with media changes" do
    let!(:product) { create(:product) }
    let!(:first_media) { create(:media, :for_product, mediaable: product, position: 0, alt: "Original") }

    def product_params
      {title: product.title, franchise_id: product.franchise_id, shape: product.shape}
    end

    it "updates media alt text" do
      patch product_path(product), params: {product: product_params, media: {"0" => {id: first_media.id.to_s, alt: "Updated alt"}}}

      expect(first_media.reload.alt).to eq("Updated alt")
    end

    it "adds new images during update" do
      blob = create_blob(filename: "new.jpg")

      patch product_path(product), params: {
        product: product_params,
        media: {"0" => {id: first_media.id.to_s}, "1" => {image_blob_id: blob.signed_id}}
      }

      expect(product.media.count).to eq(2)
    end
  end
end
