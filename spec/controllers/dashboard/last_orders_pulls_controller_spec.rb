# frozen_string_literal: true

require "rails_helper"

RSpec.describe Dashboard::LastOrdersPullsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    before { request.env["HTTP_REFERER"] = "/dashboard" }

    it "triggers the Woo sync and reenables the hook" do
      allow(Woo::PullSalesJob).to receive(:perform_later).with(pages: 2)
      allow(Config).to receive(:enable_sales_hook)

      post :create

      expect(Woo::PullSalesJob).to have_received(:perform_later).with(pages: 2)
      expect(Config).to have_received(:enable_sales_hook)
      expect(response).to redirect_to("/dashboard")
      expect(flash[:notice]).to eq("Started getting missing sales. It'll take around 5–10 minutes")
    end
  end
end
