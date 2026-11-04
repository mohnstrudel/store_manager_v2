# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchase items" do
  before { sign_in_as_admin }

  def create_image_blob(filename: "item1.jpg")
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9"),
      filename:,
      content_type: "image/jpeg"
    )
  end

  def image_upload(filename: "item1.jpg")
    Rack::Test::UploadedFile.new(
      StringIO.new("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9"),
      "image/jpeg",
      original_filename: filename
    )
  end

  describe "PATCH /purchase_items/:id" do
    it "attaches an image uploaded by the media uploader", :aggregate_failures do
      purchase_item = create(:purchase_item)
      blob = create_image_blob

      patch purchase_item_path(purchase_item), params: {
        purchase_item: {
          warehouse_id: purchase_item.warehouse_id,
          media: {"0" => {alt: "", position: "0", image: blob.signed_id, _destroy: "0"}}
        }
      }

      expect(response).to redirect_to(purchase_item_path(purchase_item))
      expect(flash[:notice]).to eq("Purchase item was successfully updated")
      expect(purchase_item.reload.media.count).to eq(1)
    end

    it "attaches files submitted as new_images", :aggregate_failures do
      purchase_item = create(:purchase_item)

      patch purchase_item_path(purchase_item), params: {
        purchase_item: {
          warehouse_id: purchase_item.warehouse_id,
          new_images: [image_upload]
        }
      }

      expect(response).to redirect_to(purchase_item_path(purchase_item))
      expect(flash[:notice]).to eq("Purchase item was successfully updated")
      expect(purchase_item.reload.media.count).to eq(1)
    end
  end

  describe "POST /purchase_items/move" do
    it "moves the selected items and returns to the source warehouse", :aggregate_failures do
      from_warehouse = create(:warehouse, name: "Warehouse From")
      to_warehouse = create(:warehouse, name: "Warehouse To")
      purchase_items = create_list(:purchase_item, 3, warehouse: from_warehouse)
      selected_items = purchase_items.first(2)

      post warehouse_move_path(warehouse_id: from_warehouse.id), params: {
        selected_items_ids: selected_items.map(&:id),
        destination_id: to_warehouse.id.to_s
      }

      expect(response).to redirect_to(warehouse_path(from_warehouse))
      expect(flash[:notice]).to eq(
        message: "Success! 2 purchased products moved to:",
        link: {label: "Warehouse To", href: warehouse_path(to_warehouse)}
      )
      expect(to_warehouse.purchase_items).to match_array(selected_items)

      follow_redirect!

      expect(inertia.props[:pagination][:total_count]).to eq(1)
    end
  end
end
