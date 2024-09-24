require "rails_helper"

RSpec.describe PurchasedProductsController, type: :controller do
  describe "DELETE #destroy" do
    it "destroys the purchased_product without destroying the associated purchase" do
      warehouse = create(:warehouse)
      purchase = create(:purchase)
      purchased_product = create_list(:purchased_product, 5, warehouse: warehouse, purchase: purchase).first

      warn PurchasedProduct.find(purchased_product.id).inspect

      expect {
        delete :destroy, params: {id: purchased_product.id}
      }.to change(PurchasedProduct, :count).by(-1)

      expect(PurchasedProduct.exists?(purchased_product.id)).to be false
      expect(Purchase.exists?(purchase.id)).to be true
      expect(response).to redirect_to(warehouse_path(warehouse))
      expect(flash[:notice]).to eq("Purchased product was successfully destroyed.")
    end
  end
end
