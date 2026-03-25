# frozen_string_literal: true

require "rails_helper"

RSpec.describe SalesController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "GET #index" do
    let!(:processing_sale) { create(:sale, status: "processing") }
    let!(:completed_sale) { create(:sale, status: "completed") }
    let!(:cancelled_sale) { create(:sale, status: "cancelled") }

    it "returns a successful response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns @sales with processing sales" do
      get :index
      expect(assigns(:sales)).to include(processing_sale)
    end

    it "excludes cancelled and completed sales" do
      get :index
      expect(assigns(:sales)).not_to include(completed_sale, cancelled_sale)
    end

    it "orders sales by shop created_at" do
      # Clean up any existing sales first
      Sale.delete_all

      create(:sale, woo_created_at: 1.day.ago)
      newer_sale = create(:sale, woo_created_at: 1.hour.ago)

      get :index
      sales = assigns(:sales).to_a
      expect(sales.first).to eq(newer_sale)
    end

    it "places older sales last in order" do
      # Clean up any existing sales first
      Sale.delete_all

      older_sale = create(:sale, woo_created_at: 1.day.ago)
      create(:sale, woo_created_at: 1.hour.ago)

      get :index
      sales = assigns(:sales).to_a
      expect(sales.last).to eq(older_sale)
    end

    it "searches sales by query parameter" do
      search_term = "test"
      allow(Sale).to receive(:search_by).with(search_term).and_return(Sale.none)

      get :index, params: {q: search_term}
      expect(Sale).to have_received(:search_by).with(search_term)
    end

    it "paginates results" do
      get :index, params: {page: 2}
      expect(assigns(:sales)).to respond_to(:current_page)
    end
  end

  describe "GET #show" do
    let(:sale) { create(:sale) }

    it "returns a successful response" do
      get :show, params: {id: sale.to_param}
      expect(response).to be_successful
    end

    it "assigns the requested sale as @sale" do
      get :show, params: {id: sale.to_param}
      expect(assigns(:sale)).to eq(sale)
    end

    it "finds sale by friendly id" do
      get :show, params: {id: sale.friendly_id}
      expect(assigns(:sale)).to eq(sale)
    end

    it "raises error for non-existent sale" do
      expect {
        get :show, params: {id: "non-existent"}
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #new" do
    it "returns a successful response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns a new sale as @sale" do
      get :new
      expect(assigns(:sale)).to be_a_new(Sale)
    end
  end

  describe "GET #edit" do
    let(:sale) { create(:sale) }

    it "returns a successful response" do
      get :edit, params: {id: sale.to_param}
      expect(response).to be_successful
    end

    it "assigns the requested sale as @sale" do
      get :edit, params: {id: sale.to_param}
      expect(assigns(:sale)).to eq(sale)
    end
  end

  describe "POST #create" do
    context "with valid params" do
      let(:valid_params) do
        {
          customer_id: create(:customer).id,
          total: 100,
          status: "processing",
          address_1: "123 Test St",
          city: "Test City",
          country: "US",
          postcode: "12345"
        }
      end

      it "creates a new Sale" do
        expect {
          post :create, params: {sale: valid_params}
        }.to change(Sale, :count).by(1)
      end

      it "assigns a newly created sale as @sale" do
        post :create, params: {sale: valid_params}
        expect(assigns(:sale)).to be_a(Sale)
      end

      it "persists the newly created sale" do
        post :create, params: {sale: valid_params}
        expect(assigns(:sale)).to be_persisted
      end

      it "redirects to the created sale" do
        post :create, params: {sale: valid_params}
        expect(response).to redirect_to(Sale.last)
      end

      it "sets a success notice" do
        post :create, params: {sale: valid_params}
        expect(flash[:notice]).to eq("Sale was successfully created")
      end

      it "delegates creation workflow to the sale model" do
        post :create, params: {sale: valid_params}

        expect(assigns(:sale)).to be_a(Sale)
      end
    end
  end

  describe "PATCH #update" do
    let(:sale) { create(:sale, status: "processing") }
    let(:new_status) { "completed" }

    context "with valid params" do
      let(:valid_params) { {status: new_status} }

      it "updates the requested sale" do
        patch :update, params: {id: sale.to_param, sale: valid_params}
        sale.reload
        expect(sale.status).to eq(new_status)
      end

      it "assigns the requested sale as @sale" do
        patch :update, params: {id: sale.to_param, sale: valid_params}
        expect(assigns(:sale)).to eq(sale)
      end

      it "redirects to the sale" do
        patch :update, params: {id: sale.to_param, sale: valid_params}
        expect(response).to redirect_to(sale)
        expect(flash[:notice]).to eq("Sale was successfully updated")
      end

    end
  end

  describe "DELETE #destroy" do
    let!(:sale) { create(:sale) }

    it "destroys the requested sale" do
      expect {
        delete :destroy, params: {id: sale.to_param}
      }.to change(Sale, :count).by(-1)
    end

    it "redirects to the sales list" do
      delete :destroy, params: {id: sale.to_param}
      expect(response).to redirect_to(sales_url)
    end

    it "sets a success notice" do
      delete :destroy, params: {id: sale.to_param}
      expect(flash[:notice]).to eq("Sale was successfully destroyed")
    end

    it "returns see_other status" do
      delete :destroy, params: {id: sale.to_param}
      expect(response).to have_http_status(:see_other)
    end
  end

end
