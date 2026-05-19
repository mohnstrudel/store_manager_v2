# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Suppliers" do
  include ActiveSupport::Testing::TimeHelpers

  before { sign_in_as_admin }

  describe "GET /suppliers" do
    it "renders the index Inertia component" do
      supplier = create(:supplier, title: "Moon Supply")

      get suppliers_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Suppliers/Index")
      expect_inertia.to have_props(
        suppliers: [
          {
            created_at: formatted_time(supplier.created_at),
            id: supplier.id,
            updated_at: formatted_time(supplier.updated_at),
            title: supplier.title
          }
        ]
      )
    end
  end

  describe "GET /suppliers/:id" do
    it "renders the show Inertia component with linked purchases" do
      supplier = create(:supplier, title: "Moon Supply")
      product = create(:product)

      travel_to(Time.zone.local(2026, 5, 19, 12, 0, 0)) do
        purchase = create(
          :purchase,
          amount: 1,
          item_price: BigDecimal("10"),
          product:,
          purchase_date: Time.zone.local(2026, 5, 19, 12, 0, 0),
          supplier:
        )

        get supplier_path(supplier)

        expect(response).to have_http_status(:ok)
        expect_inertia.to render_component("Suppliers/Show")
        expect_inertia.to have_props(
          purchases: [
            {
              amount: 1,
              debt: "10",
              has_debt: true,
              id: purchase.id,
              item_price: "10",
              path: purchase_path(purchase),
              purchased_ago: "less than a minute",
              title: product.full_title,
              variant: ""
            }
          ],
          supplier: {
            created_at: formatted_time(supplier.created_at),
            id: supplier.id,
            updated_at: formatted_time(supplier.updated_at),
            title: "Moon Supply"
          }
        )
      end
    end
  end

  describe "GET /suppliers/new" do
    it "renders the new Inertia component" do
      get new_supplier_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Suppliers/New")
    end
  end

  describe "GET /suppliers/:id/edit" do
    it "renders the edit Inertia component" do
      supplier = create(:supplier)

      get edit_supplier_path(supplier)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Suppliers/Edit")
      expect_inertia.to have_props(
        supplier: {
          created_at: formatted_time(supplier.created_at),
          id: supplier.id,
          updated_at: formatted_time(supplier.updated_at),
          title: supplier.title
        }
      )
    end
  end

  describe "POST /suppliers" do
    it "redirects to the created supplier", :aggregate_failures do
      post suppliers_path, params: {supplier: {title: "Moon Supply"}}

      expect(response).to redirect_to(supplier_path(Supplier.last))
      expect(flash[:notice]).to eq("Supplier was successfully created")
    end

    it "rerenders the new Inertia component when invalid" do
      post suppliers_path, params: {supplier: {title: ""}}

      expect(response).to redirect_to(new_supplier_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Suppliers/New")
      expect_inertia.to have_props(
        errors: {title: ["can't be blank"]},
        supplier: {created_at: nil, id: nil, updated_at: nil, title: ""}
      )
    end
  end

  describe "PATCH /suppliers/:id" do
    it "redirects to the updated supplier", :aggregate_failures do
      supplier = create(:supplier)

      patch supplier_path(supplier), params: {supplier: {title: "Moon Supply"}}

      expect(response).to redirect_to(supplier_path(supplier.reload))
      expect(supplier.reload.title).to eq("Moon Supply")
    end

    it "shares the flash notice after a successful update redirect" do
      supplier = create(:supplier)

      patch supplier_path(supplier), params: {supplier: {title: "Moon Supply"}}
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Suppliers/Show")
      expect_inertia.to have_props(flash: {notice: "Supplier was successfully updated", alert: nil})
    end

    it "rerenders the edit Inertia component when invalid" do
      supplier = create(:supplier)

      patch supplier_path(supplier), params: {supplier: {title: ""}}

      expect(response).to be_redirect
      expect(response.location).to match(%r{/suppliers/.+/edit$})

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Suppliers/Edit")
      expect_inertia.to have_props(
        errors: {title: ["can't be blank"]},
        supplier: {
          created_at: formatted_time(supplier.created_at),
          id: supplier.id,
          updated_at: formatted_time(supplier.updated_at),
          title: supplier.title
        }
      )
    end
  end

  describe "DELETE /suppliers/:id" do
    it "redirects to the index", :aggregate_failures do
      supplier = create(:supplier)

      delete supplier_path(supplier)

      expect(response).to redirect_to(suppliers_path)
      expect(Supplier.exists?(supplier.id)).to be(false)
    end
  end

  def formatted_time(time)
    time.strftime("%-d. %b '%y %H:%M")
  end
end
