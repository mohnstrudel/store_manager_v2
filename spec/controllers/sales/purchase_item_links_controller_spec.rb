# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::PurchaseItemLinksController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    let(:sale) { create(:sale) }

    before do
      allow(Sale).to receive_message_chain(:friendly, :find).with(sale.id.to_s).and_return(sale)
      allow(sale).to receive(:link_purchase_items!)
    end

    it "delegates linking workflow to the sale model" do
      post :create, params: {sale_id: sale.id}

      expect(sale).to have_received(:link_purchase_items!)
    end

    it "redirects to sale with success notice" do
      post :create, params: {sale_id: sale.id}

      expect(response).to redirect_to(sale)
      expect(flash[:notice]).to eq("Success! Sold products were interlinked with purchased products")
    end
  end
end
