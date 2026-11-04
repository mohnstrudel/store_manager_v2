# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Warehouses" do
  before { sign_in_as_admin }

  describe "GET /warehouses/new" do
    it "renders the new Inertia component with form props" do
      destination = create(:warehouse, name: "Main Stock")

      get new_warehouse_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Warehouses/New")

      warehouse_props = inertia.props[:warehouse]
      expect(warehouse_props[:id]).to be_nil
      expect(warehouse_props[:path]).to eq("")
      expect(warehouse_props[:position]).to eq(1)
      expect(inertia.props[:options][:positions]).to eq([1, 2])
      expect(inertia.props[:options][:transition_destinations].pluck(:id)).to include(
        destination.id
      )
    end
  end

  describe "GET /warehouses/:id/edit" do
    it "renders the edit Inertia component with existing form props" do
      warehouse = create(:warehouse, name: "Warehouse A")
      destination = create(:warehouse, name: "Warehouse B")
      media = create(:media, :for_warehouse, mediaable: warehouse, alt: "Warehouse image")
      create(:warehouse_transition, from_warehouse: warehouse, to_warehouse: destination)

      get edit_warehouse_path(warehouse)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Warehouses/Edit")

      warehouse_props = inertia.props[:warehouse]
      expect(warehouse_props[:id]).to eq(warehouse.id)
      expect(warehouse_props[:path]).to eq(warehouse_path(warehouse))
      expect(warehouse_props[:media].first[:id]).to eq(media.id)
      expect(warehouse_props[:transition_ids]).to eq([destination.id])
      expect(inertia.props[:options][:positions]).to eq([1, 2])
      expect(inertia.props[:options][:transition_destinations].pluck(:id)).to eq(
        [destination.id]
      )
    end
  end

  describe "GET /warehouses/:id" do
    it "renders the show component with inline tracking and shipping edit props" do
      warehouse = create(:warehouse, name: "Warehouse A")
      shipping_company = create(:shipping_company, name: "Skyline")
      purchase_item = create(
        :purchase_item,
        warehouse: warehouse,
        shipping_company: shipping_company,
        tracking_number: "TRACK-1"
      )

      get warehouse_path(warehouse)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Warehouses/Show")

      item_props = inertia.props[:purchase_items].first
      expect(item_props[:id]).to eq(purchase_item.id)
      expect(item_props[:tracking_number]).to eq("TRACK-1")
      expect(item_props[:shipping_company_id]).to eq(shipping_company.id)
      expect(item_props[:shipping_company_name]).to eq("Skyline")
      expect(inertia.props[:shipping_companies]).to include(
        id: shipping_company.id,
        name: "Skyline"
      )
      expect(inertia.props[:warehouse_move_path]).to eq(warehouse_move_path(warehouse_id: warehouse.id))
    end
  end

  describe "POST /warehouses" do
    it "creates a warehouse with a transition destination and redirects to show" do
      destination = create(:warehouse, name: "Destination")

      expect {
        post warehouses_path, params: {
          warehouse: {
            name: "Main Stock",
            external_name_en: "Main Stock",
            external_name_de: "Hauptlager",
            desc_en: "Primary warehouse",
            desc_de: "Hauptlager Beschreibung",
            cbm: "12.5",
            container_tracking_number: "CONT-1",
            courier_tracking_url: "https://track.me/CONT-1",
            is_default: "0",
            position: "1",
            to_warehouse_ids: [destination.id.to_s]
          }
        }
      }.to change(Warehouse, :count).by(1)

      warehouse = Warehouse.order(:id).last
      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(flash[:notice]).to eq("Warehouse was successfully created")
      expect(warehouse.name).to eq("Main Stock")
      expect(warehouse.from_transitions.pluck(:to_warehouse_id)).to eq([destination.id])
    end

    it "redirects to new with errors when the name is blank" do
      post warehouses_path, params: {
        warehouse: {
          name: ""
        }
      }

      expect(response).to redirect_to(new_warehouse_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Warehouses/New")
      expect(inertia.props[:errors]).to be_present
    end
  end

  describe "PATCH /warehouses/:id" do
    it "accepts submitting the edit form without changes" do
      warehouse = create(
        :warehouse,
        name: "Main Stock",
        external_name_en: "Main Stock",
        external_name_de: "Hauptlager",
        desc_en: "Primary warehouse",
        desc_de: "Hauptlager Beschreibung",
        cbm: "12.5",
        container_tracking_number: "CONT-1",
        courier_tracking_url: "https://track.me/CONT-1",
        is_default: false,
        position: 1
      )

      patch warehouse_path(warehouse), params: {
        warehouse: {
          name: "Main Stock",
          external_name_en: "Main Stock",
          external_name_de: "Hauptlager",
          desc_en: "Primary warehouse",
          desc_de: "Hauptlager Beschreibung",
          cbm: "12.5",
          container_tracking_number: "CONT-1",
          courier_tracking_url: "https://track.me/CONT-1",
          is_default: "0",
          position: "1",
          to_warehouse_ids: []
        }
      }

      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(warehouse.reload.name).to eq("Main Stock")
    end

    it "saves name and descriptions when the form also submits transition destinations" do
      warehouse = create(:warehouse, name: "Old Name", desc_en: "Old EN", desc_de: "Old DE")
      destination = create(:warehouse)

      patch warehouse_path(warehouse), params: {
        warehouse: {
          name: "New Name",
          desc_en: "New EN",
          desc_de: "New DE",
          to_warehouse_ids: [destination.id.to_s]
        }
      }

      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(warehouse.reload).to have_attributes(name: "New Name", desc_en: "New EN", desc_de: "New DE")
      expect(warehouse.from_transitions.pluck(:to_warehouse_id)).to eq([destination.id])
    end

    it "attaches uploaded images to the warehouse" do
      warehouse = create(:warehouse)
      blobs = %w[warehouse1.jpg warehouse2.jpg].map do |filename|
        ActiveStorage::Blob.create_and_upload!(
          io: StringIO.new("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9"),
          filename:,
          content_type: "image/jpeg"
        )
      end

      patch warehouse_path(warehouse), params: {
        warehouse: {
          name: warehouse.name,
          media: blobs.each_with_index.to_h do |blob, index|
            [index.to_s, {alt: "", position: index.to_s, image: blob.signed_id, _destroy: "0"}]
          end
        }
      }

      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(flash[:notice]).to eq("Warehouse was successfully updated")
      expect(warehouse.reload.media.count).to eq(2)
    end

    it "redirects to edit with errors when another default warehouse already exists" do
      warehouse = create(:warehouse)
      create(:warehouse, :default)

      patch warehouse_path(warehouse), params: {
        warehouse: {
          is_default: "1"
        }
      }

      expect(response).to redirect_to(edit_warehouse_path(warehouse))

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Warehouses/Edit")
      expect(inertia.props[:errors]).to be_present
      expect(inertia.props[:errors][:is_default]).to eq("another default warehouse already exists")
    end
  end

  describe "PATCH /warehouses/:id/change_position" do
    it "moves the warehouse to the new position and lists warehouses in the new order" do
      first = create(:warehouse, name: "Warehouse 1", position: 1)
      second = create(:warehouse, name: "Warehouse 2", position: 2)
      third = create(:warehouse, name: "Warehouse 3", position: 3)

      patch warehouse_position_path(second), params: {position: "1"}

      expect(response).to redirect_to(warehouses_url)
      expect(response).to have_http_status(:see_other)
      expect(flash[:notice]).to eq("We changed \"Warehouse 2\" position from 2 to 1")

      follow_redirect!

      warehouses = inertia.props[:warehouses]
      expect(warehouses.pluck(:id)).to eq([second.id, first.id, third.id])
      expect(warehouses.first[:positions]).to eq([1, 2, 3])
    end

    it "rejects a non-positive position without moving the warehouse" do
      warehouse = create(:warehouse, position: 1)

      patch warehouse_position_path(warehouse), params: {position: "0"}

      expect(response).to have_http_status(:bad_request)
      expect(warehouse.reload.position).to eq(1)
    end
  end

  describe "PATCH /warehouses/:id transitions" do
    let(:warehouse) { create(:warehouse) }
    let(:to_warehouse) { create(:warehouse) }

    it "creates transitions with the transition notification for selected destinations", :aggregate_failures do
      notification = create(:notification, name: "Warehouse transition")

      patch warehouse_path(warehouse), params: {warehouse: {to_warehouse_ids: [to_warehouse.id]}}

      transition = WarehouseTransition.last
      expect(transition.from_warehouse).to eq(warehouse)
      expect(transition.to_warehouse).to eq(to_warehouse)
      expect(transition.notification).to eq(notification)
    end

    it "removes transitions that are no longer selected" do
      unused_warehouse = create(:warehouse)
      create(:notification, name: "Warehouse transition")
      create(:warehouse_transition, from_warehouse: warehouse, to_warehouse: unused_warehouse)

      patch warehouse_path(warehouse), params: {warehouse: {to_warehouse_ids: [to_warehouse.id]}}

      expect(WarehouseTransition.where(to_warehouse: unused_warehouse)).to be_empty
    end

    it "keeps another warehouse from becoming the default", :aggregate_failures do
      create(:warehouse, :default, name: "Default Warehouse")

      patch warehouse_path(warehouse), params: {warehouse: {is_default: "1"}}

      expect(response).to redirect_to(edit_warehouse_path(warehouse))
      expect(warehouse.reload.is_default).to be(false)
    end

    it "returns 404 for a warehouse that does not exist" do
      patch warehouse_path(0), params: {warehouse: {name: "Missing"}}

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /warehouses/:id" do
    it "redirects back with an alert when the warehouse still has purchase items", :aggregate_failures do
      warehouse = create(:warehouse)
      create(:purchase_item, warehouse:)

      delete warehouse_path(warehouse)

      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(flash[:alert]).to include("move out all purchased products")
      expect(Warehouse.exists?(warehouse.id)).to be(true)
    end

    it "returns 404 for a warehouse that does not exist" do
      delete warehouse_path(0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /warehouses/:id inventory" do
    it "lists only the warehouse's purchase items and its media", :aggregate_failures do
      warehouse = create(:warehouse)
      matching_item = create(:purchase_item, warehouse:)
      create(:purchase_item)
      media = create(:media, :for_warehouse, mediaable: warehouse)

      get warehouse_path(warehouse)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Warehouses/Show")
      expect(inertia.props[:warehouse][:id]).to eq(warehouse.id)
      expect(inertia.props[:warehouse][:media].first[:id]).to eq(media.id)
      expect(inertia.props[:purchase_items].pluck(:id)).to eq([matching_item.id])
    end

    it "returns 404 for a warehouse that does not exist" do
      get warehouse_path(0)

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /warehouses/:id/change_position missing record" do
    it "returns 404 for a warehouse that does not exist" do
      patch warehouse_position_path(0), params: {position: "1"}

      expect(response).to have_http_status(:not_found)
    end
  end
end
