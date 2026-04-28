# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchases::ProductVariantsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "GET #show" do
    let(:product) { create(:product) }
    let!(:variant) { create(:variant, product:) }

    it "loads the product variants for the turbo stream response" do
      get :show, params: {product_id: product.id, target: "purchase_variant_id"}, format: :turbo_stream

      expect(response).to be_successful
      expect(assigns[:product]).to eq(product)
      expect(assigns[:target]).to eq("purchase_variant_id")
      expect(assigns[:variants]).to eq(product.fetch_variants_with_title)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    end
  end
end
