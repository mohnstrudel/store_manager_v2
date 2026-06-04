# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#save_editing!" do
    let(:product) { described_class.new }
    let(:warehouse) { create(:warehouse) }
    let(:supplier) { create(:supplier) }
    let(:franchise) { create(:franchise) }

    it "creates a purchase, warehouse items, and a payment" do # rubocop:disable RSpec/MultipleExpectations
      expect {
        product.save_editing!(
          product_attributes: creation_product_attributes,
          variants_attributes: [],
          store_infos_attributes: [],
          purchase_attributes: {
            supplier_id: supplier.id,
            amount: "2",
            item_price: "10",
            order_reference: "PO-1",
            warehouse_id: warehouse.id,
            payment_value: "20"
          }
        )
      }.to change(Purchase, :count).by(1)
        .and change(PurchaseItem, :count).by(2)
        .and change(Payment, :count).by(1)

      purchase = product.purchases.order(:id).last

      expect(purchase.supplier).to eq(supplier)
      expect(purchase.order_reference).to eq("PO-1")
      expect(purchase.purchase_items.pluck(:warehouse_id).uniq).to eq([warehouse.id])
      expect(purchase.payments.pluck(:value)).to eq([BigDecimal(20)])
    end

    it "raises purchase validation errors when the purchase is blank" do # rubocop:todo RSpec/MultipleExpectations
      expect {
        product.save_editing!(
          product_attributes: creation_product_attributes,
          variants_attributes: [],
          store_infos_attributes: [],
          purchase_attributes: {
            warehouse_id: warehouse.id
          }
        )
      }.to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record).to eq(product)
      }

      expect(product.errors[:initial_purchase]).to include("is invalid")
    end

    it "raises purchase validation errors when only part of the initial purchase is filled in" do # rubocop:todo RSpec/MultipleExpectations
      expect {
        product.save_editing!(
          product_attributes: creation_product_attributes,
          variants_attributes: [],
          store_infos_attributes: [],
          purchase_attributes: {
            amount: "2",
            item_price: "10",
            payment_value: "20"
          }
        )
      }.to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record).to eq(product)
      }

      expect(product.errors[:initial_purchase]).to include("is invalid")
    end

    # rubocop:todo RSpec/MessageSpies
    it "persists the purchase after the rest of the product changes" do # rubocop:todo RSpec/MultipleExpectations
      purchase = instance_double(Purchase)

      allow(Purchase).to receive(:new).and_return(purchase)
      allow(purchase).to receive_messages(valid?: true, errors: [])

      expect(product).to receive(:save!).ordered.and_call_original
      expect(purchase).to receive(:product=).with(product).ordered
      expect(purchase).to receive(:save_editing!).ordered

      product.save_editing!(
        product_attributes: creation_product_attributes,
        variants_attributes: [],
        store_infos_attributes: [],
        purchase_attributes: {
          supplier_id: supplier.id,
          amount: "2",
          item_price: "10"
        }
      )
    end
    # rubocop:enable RSpec/MessageSpies

    def creation_product_attributes
      {
        title: "Product with initial purchase",
        franchise_id: franchise.id,
        shape: Product.default_shape
      }
    end
  end
end
