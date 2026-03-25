# frozen_string_literal: true

require "rails_helper"

describe PurchaseItemsController do
  include ActionView::RecordIdentifier

  before { sign_in_as_admin }
  after { log_out }

  describe "DELETE #destroy" do
    # rubocop:todo RSpec/MultipleExpectations
    it "destroys the purchase_item without destroying the associated purchase" do
      # rubocop:enable RSpec/MultipleExpectations
      warehouse = create(:warehouse)
      purchase = create(:purchase)
      purchase_item = create_list(:purchase_item, 5, warehouse: warehouse, purchase: purchase).first

      expect {
        delete :destroy, params: {id: purchase_item.id}
      }.to change(PurchaseItem, :count).by(-1)

      expect(PurchaseItem.exists?(purchase_item.id)).to be false
      expect(Purchase.exists?(purchase.id)).to be true
      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(flash[:notice]).to eq("Purchase item was successfully destroyed")
    end
  end

end
