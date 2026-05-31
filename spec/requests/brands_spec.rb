# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Brands" do
  before { sign_in_as_admin }

  describe "GET /brands" do
    it "renders the index Inertia component" do
      brand = create(:brand, title: "Moonbow")

      get brands_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Brands/Index")
      expect_inertia.to have_props(
        brands: [
          {
            created_at: formatted_time(brand.created_at),
            id: brand.id,
            updated_at: formatted_time(brand.updated_at),
            title: brand.title
          }
        ]
      )
    end
  end

  describe "GET /brands/:id" do
    it "renders the show Inertia component with linked products" do
      brand = create(:brand, title: "Moonbow")
      product = create(:product)
      product.brands << brand

      get brand_path(brand)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Brands/Show")
      expect_inertia.to have_props(
        brand: {
          created_at: formatted_time(brand.created_at),
          id: brand.id,
          updated_at: formatted_time(brand.updated_at),
          title: "Moonbow"
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

  describe "GET /brands/new" do
    it "renders the new Inertia component" do
      get new_brand_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Brands/New")
    end
  end

  describe "GET /brands/:id/edit" do
    it "renders the edit Inertia component" do
      brand = create(:brand)

      get edit_brand_path(brand)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Brands/Edit")
      expect_inertia.to have_props(
        brand: {
          created_at: formatted_time(brand.created_at),
          id: brand.id,
          updated_at: formatted_time(brand.updated_at),
          title: brand.title
        }
      )
    end
  end

  describe "POST /brands" do
    it "redirects to the created brand", :aggregate_failures do
      post brands_path, params: {brand: {title: "Moonbow"}}

      expect(response).to redirect_to(brand_path(Brand.last))
      expect(flash[:notice]).to eq("Brand was successfully created")
    end

    it "rerenders the new Inertia component when invalid" do
      post brands_path, params: {brand: {title: ""}}

      expect(response).to redirect_to(new_brand_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Brands/New")
      expect_inertia.to have_props(
        brand: {created_at: nil, id: nil, updated_at: nil, title: ""},
        errors: {title: "Title can't be blank"}
      )
    end
  end

  describe "PATCH /brands/:id" do
    it "accepts submitting the edit form without changes", :aggregate_failures do
      brand = create(:brand, title: "Moonbow")

      patch brand_path(brand), params: {brand: {title: "Moonbow"}}

      expect(response).to redirect_to(brand_path(brand))
      expect(brand.reload.title).to eq("Moonbow")
    end

    it "redirects to the updated brand", :aggregate_failures do
      brand = create(:brand)

      patch brand_path(brand), params: {brand: {title: "Moonbow"}}

      expect(response).to redirect_to(brand_path(brand))
      expect(brand.reload.title).to eq("Moonbow")
    end

    it "shares the flash notice after a successful update redirect" do
      brand = create(:brand)

      patch brand_path(brand), params: {brand: {title: "Moonbow"}}
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Brands/Show")
      expect_inertia.to have_props(flash: {notice: "Brand was successfully updated", alert: nil})
    end

    it "rerenders the edit Inertia component when invalid" do
      brand = create(:brand)

      patch brand_path(brand), params: {brand: {title: ""}}

      expect(response).to redirect_to(edit_brand_path(brand))

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Brands/Edit")
      expect_inertia.to have_props(
        brand: {
          created_at: formatted_time(brand.created_at),
          id: brand.id,
          updated_at: formatted_time(brand.updated_at),
          title: brand.title
        },
        errors: {title: "Title can't be blank"}
      )
    end
  end

  describe "DELETE /brands/:id" do
    it "redirects to the index", :aggregate_failures do
      brand = create(:brand)

      delete brand_path(brand)

      expect(response).to redirect_to(brands_path)
      expect(Brand.exists?(brand.id)).to be(false)
    end
  end

  def formatted_time(time)
    time.strftime("%-d. %b '%y %H:%M")
  end
end
