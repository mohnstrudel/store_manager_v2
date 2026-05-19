# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sizes" do
  before { sign_in_as_admin }

  describe "GET /sizes" do
    it "renders the index Inertia component" do
      size = create(:size, value: "1:6")

      get sizes_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sizes/Index")
      expect_inertia.to have_props(
        sizes: [
          {
            id: size.id,
            value: size.value,
            created_at: formatted_time(size.created_at),
            updated_at: formatted_time(size.updated_at)
          }
        ]
      )
    end
  end

  describe "GET /sizes/:id" do
    it "renders the show Inertia component with linked products" do
      size = create(:size, value: "1:6")
      product = create(:product, sizes: [size])

      get size_path(size)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sizes/Show")
      expect_inertia.to have_props(
        size: {
          id: size.id,
          value: "1:6",
          created_at: formatted_time(size.created_at),
          updated_at: formatted_time(size.updated_at)
        },
        products: [
          {
            id: product.id,
            full_title: product.full_title,
            path: product_path(product)
          }
        ]
      )
    end
  end

  describe "GET /sizes/new" do
    it "renders the new Inertia component" do
      get new_size_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sizes/New")
    end
  end

  describe "GET /sizes/:id/edit" do
    it "renders the edit Inertia component" do
      size = create(:size)

      get edit_size_path(size)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sizes/Edit")
      expect_inertia.to have_props(
        size: {
          id: size.id,
          value: size.value,
          created_at: formatted_time(size.created_at),
          updated_at: formatted_time(size.updated_at)
        }
      )
    end
  end

  describe "POST /sizes" do
    it "redirects to the created size", :aggregate_failures do
      post sizes_path, params: {size: {value: "1:8"}}

      expect(response).to redirect_to(size_path(Size.last))
      expect(flash[:notice]).to eq("Size was successfully created")
    end

    it "rerenders the new Inertia component when invalid" do
      post sizes_path, params: {size: {value: ""}}

      expect(response).to have_http_status(:unprocessable_content)
      expect_inertia.to render_component("Sizes/New")
      expect_inertia.to have_props(
        errors: {value: ["Value can't be blank"]},
        size: {id: nil, value: "", created_at: nil, updated_at: nil}
      )
    end
  end

  describe "PATCH /sizes/:id" do
    it "redirects to the updated size", :aggregate_failures do
      size = create(:size)

      patch size_path(size), params: {size: {value: "1:10"}}

      expect(response).to redirect_to(size_path(size))
      expect(size.reload.value).to eq("1:10")
    end

    it "shares the flash notice after a successful update redirect" do
      size = create(:size)

      patch size_path(size), params: {size: {value: "1:10"}}
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Sizes/Show")
      expect_inertia.to have_props(flash: {notice: "Size was successfully updated", alert: nil})
    end

    it "rerenders the edit Inertia component when invalid" do
      size = create(:size)

      patch size_path(size), params: {size: {value: ""}}

      expect(response).to have_http_status(:unprocessable_content)
      expect_inertia.to render_component("Sizes/Edit")
      expect_inertia.to have_props(
        errors: {value: ["Value can't be blank"]},
        size: {
          id: size.id,
          value: "",
          created_at: formatted_time(size.created_at),
          updated_at: formatted_time(size.updated_at)
        }
      )
    end
  end

  describe "DELETE /sizes/:id" do
    it "redirects to the index", :aggregate_failures do
      size = create(:size)

      delete size_path(size)

      expect(response).to redirect_to(sizes_path)
      expect(Size.exists?(size.id)).to be(false)
    end
  end

  def formatted_time(time)
    time.strftime("%-d. %b '%y %H:%M")
  end
end
