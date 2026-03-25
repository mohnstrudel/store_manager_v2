# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchases::ProductEditionsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "GET #show" do
    let(:product) { create(:product) }
    let!(:edition) { create(:edition, product:) }

    it "loads the product editions for the turbo stream response" do
      get :show, params: {product_id: product.id, target: "purchase_edition_id"}, format: :turbo_stream

      expect(response).to be_successful
      expect(assigns[:product]).to eq(product)
      expect(assigns[:target]).to eq("purchase_edition_id")
      expect(assigns[:editions]).to eq(product.fetch_editions_with_title)
      expect(response.media_type).to eq(Mime[:turbo_stream].to_s)
    end
  end
end
