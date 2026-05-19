# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Franchises" do
  before { sign_in_as_admin }

  describe "GET /franchises" do
    it "renders the index Inertia component" do
      franchise = create(:franchise, title: "Moonbase")

      get franchises_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Franchises/Index")
      expect_inertia.to have_props(
        franchises: [
          {
            created_at: formatted_time(franchise.created_at),
            id: franchise.id,
            updated_at: formatted_time(franchise.updated_at),
            title: franchise.title
          }
        ]
      )
    end
  end

  describe "GET /franchises/:id" do
    it "renders the show Inertia component with linked products" do
      franchise = create(:franchise, title: "Moonbase")
      product = create(:product, franchise:)

      get franchise_path(franchise)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Franchises/Show")
      expect_inertia.to have_props(
        franchise: {
          created_at: formatted_time(franchise.created_at),
          id: franchise.id,
          updated_at: formatted_time(franchise.updated_at),
          title: "Moonbase"
        },
        products: [
          {
            full_title: product.full_title,
            id: product.id,
            path: product_path(product)
          }
        ]
      )
    end
  end

  describe "GET /franchises/new" do
    it "renders the new Inertia component" do
      get new_franchise_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Franchises/New")
    end
  end

  describe "GET /franchises/:id/edit" do
    it "renders the edit Inertia component" do
      franchise = create(:franchise)

      get edit_franchise_path(franchise)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Franchises/Edit")
      expect_inertia.to have_props(
        franchise: {
          created_at: formatted_time(franchise.created_at),
          id: franchise.id,
          updated_at: formatted_time(franchise.updated_at),
          title: franchise.title
        }
      )
    end
  end

  describe "POST /franchises" do
    it "redirects to the created franchise", :aggregate_failures do
      post franchises_path, params: {franchise: {title: "Moonbase"}}

      expect(response).to redirect_to(franchise_path(Franchise.last))
      expect(flash[:notice]).to eq("Franchise was successfully created")
    end

    it "rerenders the new Inertia component when invalid" do
      post franchises_path, params: {franchise: {title: ""}}

      expect(response).to have_http_status(:unprocessable_content)
      expect_inertia.to render_component("Franchises/New")
      expect_inertia.to have_props(
        errors: {title: ["Title can't be blank"]},
        franchise: {created_at: nil, id: nil, updated_at: nil, title: ""}
      )
    end
  end

  describe "PATCH /franchises/:id" do
    it "redirects to the updated franchise", :aggregate_failures do
      franchise = create(:franchise)

      patch franchise_path(franchise), params: {franchise: {title: "Moonbase"}}

      expect(response).to redirect_to(franchise_path(franchise))
      expect(franchise.reload.title).to eq("Moonbase")
    end

    it "shares the flash notice after a successful update redirect" do
      franchise = create(:franchise)

      patch franchise_path(franchise), params: {franchise: {title: "Moonbase"}}
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Franchises/Show")
      expect_inertia.to have_props(flash: {notice: "Franchise was successfully updated", alert: nil})
    end

    it "rerenders the edit Inertia component when invalid" do
      franchise = create(:franchise)

      patch franchise_path(franchise), params: {franchise: {title: ""}}

      expect(response).to have_http_status(:unprocessable_content)
      expect_inertia.to render_component("Franchises/Edit")
      expect_inertia.to have_props(
        errors: {title: ["Title can't be blank"]},
        franchise: {
          created_at: formatted_time(franchise.created_at),
          id: franchise.id,
          updated_at: formatted_time(franchise.updated_at),
          title: ""
        }
      )
    end
  end

  describe "DELETE /franchises/:id" do
    it "redirects to the index", :aggregate_failures do
      franchise = create(:franchise)

      delete franchise_path(franchise)

      expect(response).to redirect_to(franchises_path)
      expect(Franchise.exists?(franchise.id)).to be(false)
    end
  end

  def formatted_time(time)
    time.strftime("%-d. %b '%y %H:%M")
  end
end
