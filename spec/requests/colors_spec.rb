# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Colors" do
  before { sign_in_as_admin }

  describe "GET /colors" do
    it "renders the index Inertia component" do
      color = create(:color, value: "Azure")

      get colors_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Colors/Index")
      expect_inertia.to have_props(
        colors: [
          {
            created_at: formatted_time(color.created_at),
            id: color.id,
            updated_at: formatted_time(color.updated_at),
            value: color.value
          }
        ]
      )
    end
  end

  describe "GET /colors/:id" do
    it "renders the show Inertia component with linked products" do
      color = create(:color, value: "Azure")
      product = create(:product)
      product.colors << color

      get color_path(color)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Colors/Show")
      expect_inertia.to have_props(
        color: {
          created_at: formatted_time(color.created_at),
          id: color.id,
          updated_at: formatted_time(color.updated_at),
          value: "Azure"
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

  describe "GET /colors/new" do
    it "renders the new Inertia component" do
      get new_color_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Colors/New")
    end
  end

  describe "GET /colors/:id/edit" do
    it "renders the edit Inertia component" do
      color = create(:color)

      get edit_color_path(color)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Colors/Edit")
      expect_inertia.to have_props(
        color: {
          created_at: formatted_time(color.created_at),
          id: color.id,
          updated_at: formatted_time(color.updated_at),
          value: color.value
        }
      )
    end
  end

  describe "POST /colors" do
    it "redirects to the created color", :aggregate_failures do
      post colors_path, params: {color: {value: "Azure"}}

      expect(response).to redirect_to(color_path(Color.last))
      expect(flash[:notice]).to eq("Color was successfully created")
    end

    it "rerenders the new Inertia component when invalid" do
      post colors_path, params: {color: {value: ""}}

      expect(response).to have_http_status(:unprocessable_content)
      expect_inertia.to render_component("Colors/New")
      expect_inertia.to have_props(
        color: {created_at: nil, id: nil, updated_at: nil, value: ""},
        errors: {value: ["Value can't be blank"]}
      )
    end
  end

  describe "PATCH /colors/:id" do
    it "redirects to the updated color", :aggregate_failures do
      color = create(:color)

      patch color_path(color), params: {color: {value: "Azure"}}

      expect(response).to redirect_to(color_path(color))
      expect(color.reload.value).to eq("Azure")
    end

    it "shares the flash notice after a successful update redirect" do
      color = create(:color)

      patch color_path(color), params: {color: {value: "Azure"}}
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Colors/Show")
      expect_inertia.to have_props(flash: {notice: "Color was successfully updated", alert: nil})
    end

    it "rerenders the edit Inertia component when invalid" do
      color = create(:color)

      patch color_path(color), params: {color: {value: ""}}

      expect(response).to have_http_status(:unprocessable_content)
      expect_inertia.to render_component("Colors/Edit")
      expect_inertia.to have_props(
        color: {
          created_at: formatted_time(color.created_at),
          id: color.id,
          updated_at: formatted_time(color.updated_at),
          value: ""
        },
        errors: {value: ["Value can't be blank"]}
      )
    end
  end

  describe "DELETE /colors/:id" do
    it "redirects to the index", :aggregate_failures do
      color = create(:color)

      delete color_path(color)

      expect(response).to redirect_to(colors_path)
      expect(Color.exists?(color.id)).to be(false)
    end
  end

  def formatted_time(time)
    time.strftime("%-d. %b '%y %H:%M")
  end
end
