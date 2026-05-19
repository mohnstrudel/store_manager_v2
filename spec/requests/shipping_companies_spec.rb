# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ShippingCompanies" do
  include ActiveSupport::Testing::TimeHelpers

  before { sign_in_as_admin }

  describe "GET /shipping_companies" do
    it "renders the index Inertia component" do
      shipping_company = create(:shipping_company, name: "Skyline")

      get shipping_companies_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("ShippingCompanies/Index")
      expect_inertia.to have_props(
        shippingCompanies: [
          {
            created_at: formatted_time(shipping_company.created_at),
            id: shipping_company.id,
            name: shipping_company.name,
            tracking_url: shipping_company.tracking_url,
            updated_at: formatted_time(shipping_company.updated_at)
          }
        ]
      )
    end
  end

  describe "GET /shipping_companies/:id" do
    it "renders the show Inertia component with linked purchase items" do
      shipping_company = create(:shipping_company, name: "Skyline")
      product = create(:product)

      travel_to(Time.zone.local(2026, 5, 19, 12, 0, 0)) do
        purchase = create(
          :purchase,
          amount: 1,
          item_price: BigDecimal("10"),
          product:,
          purchase_date: Time.zone.local(2026, 5, 19, 12, 0, 0)
        )
        purchase_item = create(
          :purchase_item,
          purchase:,
          shipping_company:,
          tracking_number: "TN-123"
        )

        get shipping_company_path(shipping_company)

        expect(response).to have_http_status(:ok)
        expect_inertia.to render_component("ShippingCompanies/Show")
        expect_inertia.to have_props(
          purchaseItems: [
            {
              id: purchase_item.id,
              path: purchase_item_path(purchase_item),
              product_full_title: product.full_title,
              purchased_ago: "less than a minute",
              tracking_number: "TN-123"
            }
          ],
          shippingCompany: {
            created_at: formatted_time(shipping_company.created_at),
            id: shipping_company.id,
            name: "Skyline",
            tracking_url: shipping_company.tracking_url,
            updated_at: formatted_time(shipping_company.updated_at)
          }
        )
      end
    end
  end

  describe "GET /shipping_companies/new" do
    it "renders the new Inertia component" do
      get new_shipping_company_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("ShippingCompanies/New")
    end
  end

  describe "GET /shipping_companies/:id/edit" do
    it "renders the edit Inertia component" do
      shipping_company = create(:shipping_company)

      get edit_shipping_company_path(shipping_company)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("ShippingCompanies/Edit")
      expect_inertia.to have_props(
        shippingCompany: {
          created_at: formatted_time(shipping_company.created_at),
          id: shipping_company.id,
          name: shipping_company.name,
          tracking_url: shipping_company.tracking_url,
          updated_at: formatted_time(shipping_company.updated_at)
        }
      )
    end
  end

  describe "POST /shipping_companies" do
    it "redirects to the created shipping company", :aggregate_failures do
      post shipping_companies_path, params: {shipping_company: {name: "Skyline", tracking_url: "https://track.me"}}

      expect(response).to redirect_to(shipping_company_path(ShippingCompany.last))
      expect(flash[:notice]).to eq("Shipping company was successfully created")
    end

    it "rerenders the new Inertia component when invalid" do
      post shipping_companies_path, params: {shipping_company: {name: "Skyline", tracking_url: ""}}

      expect(response).to redirect_to(new_shipping_company_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("ShippingCompanies/New")
      expect_inertia.to have_props(
        errors: {tracking_url: ["can't be blank"]},
        shippingCompany: {
          created_at: nil,
          id: nil,
          name: "",
          tracking_url: nil,
          updated_at: nil
        }
      )
    end
  end

  describe "PATCH /shipping_companies/:id" do
    it "redirects to the updated shipping company", :aggregate_failures do
      shipping_company = create(:shipping_company)

      patch shipping_company_path(shipping_company), params: {
        shipping_company: {name: "Skyline", tracking_url: "https://track.me"}
      }

      expect(response).to redirect_to(shipping_company_path(shipping_company))
      expect(shipping_company.reload.name).to eq("Skyline")
    end

    it "shares the flash notice after a successful update redirect" do
      shipping_company = create(:shipping_company)

      patch shipping_company_path(shipping_company), params: {
        shipping_company: {name: "Skyline", tracking_url: "https://track.me"}
      }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("ShippingCompanies/Show")
      expect_inertia.to have_props(
        flash: {notice: "Shipping company was successfully updated", alert: nil}
      )
    end

    it "rerenders the edit Inertia component when invalid" do
      shipping_company = create(:shipping_company)

      patch shipping_company_path(shipping_company), params: {
        shipping_company: {name: "Skyline", tracking_url: ""}
      }

      expect(response).to redirect_to(edit_shipping_company_path(shipping_company))

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("ShippingCompanies/Edit")
      expect_inertia.to have_props(
        errors: {tracking_url: ["can't be blank"]},
        shippingCompany: {
          created_at: formatted_time(shipping_company.created_at),
          id: shipping_company.id,
          name: shipping_company.name,
          tracking_url: shipping_company.tracking_url,
          updated_at: formatted_time(shipping_company.updated_at)
        }
      )
    end
  end

  describe "DELETE /shipping_companies/:id" do
    it "redirects to the index", :aggregate_failures do
      shipping_company = create(:shipping_company)

      delete shipping_company_path(shipping_company)

      expect(response).to redirect_to(shipping_companies_path)
      expect(ShippingCompany.exists?(shipping_company.id)).to be(false)
    end
  end

  def formatted_time(time)
    time.strftime("%-d. %b '%y %H:%M")
  end
end
