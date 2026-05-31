# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Customers" do
  before { sign_in_as_admin }

  describe "GET /customers" do
    it "renders the index Inertia component with pagination and search" do
      customer = create(:customer)

      get customers_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Customers/Index")
      expect_inertia.to have_props(
        pagination: {current_page: 1, total_pages: 1, total_count: 1, limit: 50},
        search: {q: ""}
      )

      customer_props = inertia.props[:customers].first
      expect(customer_props[:id]).to eq(customer.id)
      expect(customer_props[:email]).to eq(customer.email)
    end

    it "filters customers by search query" do
      dale = create(:customer, first_name: "Dale", email: "dale@fbi.gov")
      _laura = create(:customer, first_name: "Laura", email: "laura@black_lodge.io")

      get customers_path, params: {q: "dale"}

      expect_inertia.to have_props(search: {q: "dale"})
      expect(inertia.props[:customers].map { |c| c[:id] }).to eq([dale.id])
    end
  end

  describe "GET /customers/:id" do
    it "renders the show Inertia component" do
      customer = create(:customer)

      get customer_path(customer)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Customers/Show")
      expect_inertia.to have_props(active_sales: [], completed_sales: [])

      customer_props = inertia.props[:customer]
      expect(customer_props[:id]).to eq(customer.id)
      expect(customer_props[:email]).to eq(customer.email)
    end
  end

  describe "GET /customers/new" do
    it "renders the new Inertia component" do
      get new_customer_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Customers/New")

      customer_props = inertia.props[:customer]
      expect(customer_props[:id]).to be_nil
    end
  end

  describe "GET /customers/:id/edit" do
    it "renders the edit Inertia component" do
      customer = create(:customer)

      get edit_customer_path(customer)

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Customers/Edit")

      customer_props = inertia.props[:customer]
      expect(customer_props[:id]).to eq(customer.id)
    end
  end

  describe "POST /customers" do
    it "redirects to the created customer", :aggregate_failures do
      post customers_path, params: {
        customer: {first_name: "Dale", last_name: "Cooper", email: "dale@fbi.gov", phone: ""}
      }

      expect(response).to redirect_to(customer_path(Customer.last))
      expect(flash[:notice]).to eq("Customer was successfully created")
    end

    it "rerenders the new Inertia component when invalid" do
      post customers_path, params: {customer: {first_name: "", last_name: "", email: "", phone: ""}}

      expect(response).to redirect_to(new_customer_path)

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Customers/New")
      expect_inertia.to have_props(
        errors: {base: "Customer must have contact details or store information"}
      )
    end
  end

  describe "PATCH /customers/:id" do
    it "accepts submitting the edit form without changes", :aggregate_failures do
      customer = create(:customer, first_name: "Dale", last_name: "Cooper", email: "dale@fbi.gov", phone: "")

      patch customer_path(customer), params: {
        customer: {first_name: "Dale", last_name: "Cooper", email: "dale@fbi.gov", phone: ""}
      }

      expect(response).to redirect_to(customer_path(customer))
      expect(customer.reload.email).to eq("dale@fbi.gov")
    end

    it "redirects to the updated customer", :aggregate_failures do
      customer = create(:customer)

      patch customer_path(customer), params: {
        customer: {first_name: "Agent", last_name: "Cooper", email: "cooper@fbi.gov", phone: ""}
      }

      expect(response).to redirect_to(customer_path(customer))
      expect(customer.reload.first_name).to eq("Agent")
    end

    it "shares the flash notice after a successful update redirect" do
      customer = create(:customer)

      patch customer_path(customer), params: {
        customer: {first_name: "Agent", last_name: "Cooper", email: "cooper@fbi.gov", phone: ""}
      }
      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Customers/Show")
      expect_inertia.to have_props(flash: {notice: "Customer was successfully updated", alert: nil})
    end

    it "rerenders the edit Inertia component when invalid" do
      customer = create(:customer)
      customer.woo_info.destroy!

      patch customer_path(customer), params: {
        customer: {first_name: "", last_name: "", email: "", phone: ""}
      }

      expect(response).to redirect_to(edit_customer_path(customer))

      follow_redirect!

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("Customers/Edit")
      expect_inertia.to have_props(
        errors: {base: "Customer must have contact details or store information"}
      )
    end
  end

  describe "DELETE /customers/:id" do
    it "redirects to the index", :aggregate_failures do
      customer = create(:customer)

      delete customer_path(customer)

      expect(response).to redirect_to(customers_path)
      expect(Customer.exists?(customer.id)).to be(false)
    end
  end
end
