# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchases::ProductVariantsController do
  before { sign_in_as_admin }
  after { log_out }

  describe "GET #show" do
    let(:product) { create(:product) }
    let!(:variant) { create(:variant, product:) }

    it "returns the product variants for the dynamic purchase form select" do
      get :show, params: {product_id: product.id}

      expect(response).to be_successful
      expect(response.parsed_body.fetch("variants")).to include(
        {"value" => variant.id, "label" => variant.title}
      )
    end
  end
end
