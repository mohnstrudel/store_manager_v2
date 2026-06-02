# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Versions" do
  before { sign_in_as_admin }

  describe "GET /versions" do
    it "renders the index Inertia component" do
      version = create(:version, value: "XL")

      get versions_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Versions/Index")
      expect_inertia.to have_props(
        versions: [
          {
            created_at: formatted_time(version.created_at),
            id: version.id,
            updated_at: formatted_time(version.updated_at),
            value: version.value
          }
        ]
      )
    end
  end

  describe "GET /versions/:id" do
    it "renders the show Inertia component with linked products" do
      version = create(:version, value: "XL")
      product = create(:product)
      product.versions << version

      get version_path(version)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Versions/Show")
      expect_inertia.to have_props(
        products: [
          {
            full_title: product.full_title,
            id: product.id,
            path: product_path(product)
          }
        ],
        version: {
          created_at: formatted_time(version.created_at),
          id: version.id,
          updated_at: formatted_time(version.updated_at),
          value: "XL"
        }
      )
    end
  end

  describe "GET /versions/new" do
    it "renders the new Inertia component" do
      get new_version_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Versions/New")
    end
  end

  describe "GET /versions/:id/edit" do
    it "renders the edit Inertia component" do
      version = create(:version)

      get edit_version_path(version)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Versions/Edit")
      expect_inertia.to have_props(
        version: {
          created_at: formatted_time(version.created_at),
          id: version.id,
          updated_at: formatted_time(version.updated_at),
          value: version.value
        }
      )
    end
  end

  describe "POST /versions" do
    it "redirects to the created version", :aggregate_failures do
      post versions_path, params: {version: {value: "XL"}}

      expect(response).to redirect_to(version_path(Version.last))
      expect(flash[:notice]).to eq("Version was successfully created")
    end

    it "rerenders the new Inertia component when invalid" do
      post versions_path, params: {version: {value: ""}}

      expect(response).to redirect_to(new_version_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Versions/New")
      expect_inertia.to have_props(
        errors: {value: "can't be blank"},
        version: {created_at: nil, id: nil, updated_at: nil, value: ""}
      )
    end
  end

  describe "PATCH /versions/:id" do
    it "accepts submitting the edit form without changes", :aggregate_failures do
      version = create(:version, value: "XL")

      patch version_path(version), params: {version: {value: "XL"}}

      expect(response).to redirect_to(version_path(version))
      expect(version.reload.value).to eq("XL")
    end

    it "redirects to the updated version", :aggregate_failures do
      version = create(:version)

      patch version_path(version), params: {version: {value: "XL"}}

      expect(response).to redirect_to(version_path(version))
      expect(version.reload.value).to eq("XL")
    end

    it "shares the flash notice after a successful update redirect" do
      version = create(:version)

      patch version_path(version), params: {version: {value: "XL"}}
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Versions/Show")
      expect_inertia.to have_props(flash: {notice: "Version was successfully updated", alert: nil})
    end

    it "rerenders the edit Inertia component when invalid" do
      version = create(:version)

      patch version_path(version), params: {version: {value: ""}}

      expect(response).to redirect_to(edit_version_path(version))

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Versions/Edit")
      expect_inertia.to have_props(
        errors: {value: "can't be blank"},
        version: {
          created_at: formatted_time(version.created_at),
          id: version.id,
          updated_at: formatted_time(version.updated_at),
          value: version.value
        }
      )
    end
  end

  describe "DELETE /versions/:id" do
    it "redirects to the index", :aggregate_failures do
      version = create(:version)

      delete version_path(version)

      expect(response).to redirect_to(versions_path)
      expect(Version.exists?(version.id)).to be(false)
    end
  end

  def formatted_time(time)
    time.strftime("%-d. %b '%y %H:%M")
  end
end
