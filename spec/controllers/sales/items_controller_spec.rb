# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::ItemsController do
  before { sign_in_as_admin }
  after { log_out }

  let(:sale) { create(:sale) }
  let(:sale_item) { create(:sale_item, sale:) }

  describe "GET #show" do
    it "returns a successful response" do # rubocop:disable RSpec/MultipleExpectations
      get :show, params: {sale_id: sale.id, id: sale_item.id}

      expect(response).to be_successful
      expect(assigns[:sale]).to eq(sale)
      expect(assigns[:sale_item]).to eq(sale_item)
    end
  end

  describe "DELETE #destroy" do
    it "removes the sale item and redirects back to the sale edit screen" do # rubocop:disable RSpec/MultipleExpectations
      sale_item

      expect {
        delete :destroy, params: {sale_id: sale.id, id: sale_item.id, return_to: edit_sale_path(sale)}
      }.to change(SaleItem, :count).by(-1)

      expect(response).to redirect_to(edit_sale_path(sale))
    end
  end
end
