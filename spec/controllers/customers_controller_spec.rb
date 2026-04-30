# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomersController do
  render_views

  before { sign_in_as_admin }
  after { log_out }

  describe "GET #index" do
    it "preloads Woo store information after search filters are applied" do
      customer = create(:customer, first_name: "Michele", woo_store_id: "woo-customer-1")
      create(:customer, first_name: "Alice", woo_store_id: "woo-customer-2")

      get :index, params: {q: "Michele"}

      listed_customer = assigns(:customers).find { |assigned_customer| assigned_customer.id == customer.id }

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(listed_customer).to be_present
        expect(listed_customer.association(:woo_info)).to be_loaded
        expect(response.body).to include("woo-customer-1")
      end
    end
  end

  describe "POST #create" do
    it "does not create an empty customer" do
      expect {
        post :create, params: {
          customer: {
            email: "",
            first_name: "",
            last_name: "",
            phone: ""
          }
        }
      }.not_to change(Customer, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
