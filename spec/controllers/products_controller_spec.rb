# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductsController do
  render_views

  before { sign_in_as_admin }
  after { log_out }

  describe "GET #show" do
    let(:product) { create(:product) }
    let(:media) { create_list(:media, 2, :for_product, mediaable: product) }

    it "renders the shared gallery for product media" do
      media
      get :show, params: {id: product.to_param}

      aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('data-controller="gallery"')
        expect(response.body).to include('data-gallery-target="main"')
        expect(response.body).to include('data-gallery-target="slide"')
      end
    end
  end

  describe "PATCH #update" do
    let(:product) { create(:product, title: "Original Title") }

    it "rehydrates submitted attributes after a failed update" do # rubocop:disable RSpec/MultipleExpectations
      patch :update, params: {
        id: product.to_param,
        product: {
          title: "",
          sku: product.sku,
          franchise_id: product.franchise_id,
          shape_id: product.shape_id
        }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response).to render_template(:edit)
      expect(assigns(:product).title).to eq("")
      expect(assigns(:product).errors[:title]).to include("can't be blank")
    end
  end
end
