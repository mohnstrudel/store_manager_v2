# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductsController do
  before { sign_in_as_admin }
  after { log_out }

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
