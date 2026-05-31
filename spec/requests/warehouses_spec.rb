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
      expect(inertia.props[:options][:transition_destinations].map { |option| option[:id] }).to include(
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
      expect(inertia.props[:options][:transition_destinations].map { |option| option[:id] }).to eq(
        [destination.id]
      )
    end
  end

  describe "POST /warehouses" do
    it "creates a warehouse and redirects to show" do
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
            to_warehouse_ids: []
          }
        }
      }.to change(Warehouse, :count).by(1)

      warehouse = Warehouse.order(:id).last
      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(warehouse.name).to eq("Main Stock")
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
      expect(inertia.props[:errors][:is_default]).to eq("Is default another default warehouse already exists")
    end
  end
end
