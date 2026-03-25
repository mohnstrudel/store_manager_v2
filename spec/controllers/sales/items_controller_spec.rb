# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::ItemsController, type: :controller do
  before { sign_in_as_admin }
  after { log_out }

  let(:sale) { create(:sale) }
  let(:sale_item) { create(:sale_item, sale:) }

  describe "GET #show" do
    it "returns a successful response" do
      get :show, params: {sale_id: sale.id, id: sale_item.id}

      expect(response).to be_successful
      expect(assigns[:sale]).to eq(sale)
      expect(assigns[:sale_item]).to eq(sale_item)
    end
  end

  describe "PATCH #update" do
    it "updates the sale item and redirects to the nested show page" do
      patch :update, params: {
        sale_id: sale.id,
        id: sale_item.id,
        sale_item: {
          price: "99.99",
          qty: 3,
          edition_id: sale_item.edition_id,
          woo_id: sale_item.woo_id,
          sale_id: sale.id
        }
      }

      expect(response).to redirect_to(sale_item_path(sale, sale_item))
      expect(sale_item.reload.qty).to eq(3)
    end
  end
end
