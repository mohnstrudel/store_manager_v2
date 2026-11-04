# frozen_string_literal: true

require "rails_helper"

describe DashboardController do
  before { sign_in_as_admin }
  after { log_out }

  describe "GET #noop" do
    it "returns successful response" do
      get :noop
      expect(response).to be_successful
      expect_inertia.to render_component("Dashboard/Noop")
    end
  end

  describe "Purchase model optimizations" do
    let!(:purchase) { create(:purchase) }

    before { create_list(:purchase_item, 3, purchase: purchase, shipping_cost: 5.0) }

    it "calculates shipping_total correctly" do
      purchase.reload
      expect(purchase.shipping_total).to eq(15.0)
    end

    it "shipping_total is updated via callback" do
      expect(purchase.shipping_total).to eq(15.0)
    end
  end
end
