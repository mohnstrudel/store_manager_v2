# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchasesController do
  before { sign_in_as_admin }
  after { log_out }

  describe "POST #create" do
    let(:supplier) { create(:supplier) }
    let(:product) { create(:product) }
    let(:warehouse) { create(:warehouse) }

    it "creates the purchase, assigns its items to the selected warehouse, and adds the initial payment" do # rubocop:disable RSpec/MultipleExpectations
      expect {
        post :create, params: {
          purchase: {
            supplier_id: supplier.id,
            product_id: product.id,
            amount: 2,
            item_price: "10.00",
            warehouse_id: warehouse.id
          },
          initial_payment: {
            value: "20.00"
          }
        }
      }.to change(Purchase, :count).by(1)

      purchase = Purchase.last
      expect(response).to redirect_to(purchase_path(purchase))
      expect(purchase.purchase_items.pluck(:warehouse_id).uniq).to eq([warehouse.id])
      expect(purchase.payments.pluck(:value)).to eq([BigDecimal(20)])
    end
  end

  describe "PATCH #update" do
    let(:purchase) { create(:purchase) }

    # rubocop:disable RSpec/MultipleExpectations
    it "updates the purchase through the normalized payload" do
      patch :update, params: {
        id: purchase.to_param,
        purchase: {
          supplier_id: purchase.supplier_id,
          product_id: purchase.product_id,
          edition_id: purchase.edition_id,
          amount: 3,
          item_price: purchase.item_price,
          order_reference: "UPDATED-REF"
        }
      }

      expect(response).to redirect_to(purchase_path(purchase.reload))
      expect(purchase.order_reference).to eq("UPDATED-REF")
    end
    # rubocop:enable RSpec/MultipleExpectations
  end
end
