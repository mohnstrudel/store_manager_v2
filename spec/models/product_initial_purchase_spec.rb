# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#save_editing!" do
    let(:product) { described_class.new }
    let(:warehouse) { create(:warehouse) }
    let(:supplier) { create(:supplier) }
    let(:franchise) { create(:franchise) }
    let(:shape) { create(:shape) }

    it "creates a purchase, warehouse items, and a payment" do # rubocop:disable RSpec/MultipleExpectations
      expect {
        product.save_editing!(
          product_attributes: creation_product_attributes,
          editions_attributes: [],
          store_infos_attributes: [],
          purchase_attributes: {
            supplier_id: supplier.id,
            amount: "2",
            item_price: "10",
            order_reference: "PO-1",
            warehouse_id: warehouse.id,
            payment_value: "20"
          },
          new_media_images: []
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
          editions_attributes: [],
          store_infos_attributes: [],
          purchase_attributes: {
            warehouse_id: warehouse.id
          },
          new_media_images: []
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
          editions_attributes: [],
          store_infos_attributes: [],
          purchase_attributes: {
            amount: "2",
            item_price: "10",
            payment_value: "20"
          },
          new_media_images: []
        )
      }.to raise_error(ActiveRecord::RecordInvalid) { |error|
        expect(error.record).to eq(product)
      }

      expect(product.errors[:initial_purchase]).to include("is invalid")
    end

    it "enqueues Shopify product creation after a successful create" do
      allow(Shopify::CreateProductJob).to receive(:perform_later)

      product.save_editing!(
        product_attributes: creation_product_attributes,
        editions_attributes: [],
        store_infos_attributes: [],
        new_media_images: []
      )

      expect(Shopify::CreateProductJob).to have_received(:perform_later).with(product.id)
    end

    it "does not enqueue Shopify product creation when validation fails" do
      allow(Shopify::CreateProductJob).to receive(:perform_later)

      expect {
        product.save_editing!(
          product_attributes: creation_product_attributes.merge(title: ""),
          editions_attributes: [],
          store_infos_attributes: [],
          new_media_images: []
        )
      }.to raise_error(ActiveRecord::RecordInvalid)

      expect(Shopify::CreateProductJob).not_to have_received(:perform_later)
    end

    it "does not enqueue Shopify product creation on update" do
      persisted_product = create(:product)
      allow(Shopify::CreateProductJob).to receive(:perform_later)

      persisted_product.save_editing!(
        product_attributes: {
          title: "Updated title",
          sku: persisted_product.sku,
          franchise_id: persisted_product.franchise_id,
          shape_id: persisted_product.shape_id
        },
        editions_attributes: [],
        store_infos_attributes: [],
        new_media_images: []
      )

      expect(Shopify::CreateProductJob).not_to have_received(:perform_later)
    end

    # rubocop:todo RSpec/MessageSpies
    it "persists the purchase after the rest of the product changes" do # rubocop:todo RSpec/MultipleExpectations
      purchase = instance_double(Purchase)

      allow(Purchase).to receive(:new).and_return(purchase)
      allow(purchase).to receive(:valid?).and_return(true)

      expect(product).to receive(:save!).ordered.and_call_original
      expect(product).to receive(:add_new_media_from_form!).ordered.and_call_original
      expect(purchase).to receive(:product=).with(product).ordered
      expect(purchase).to receive(:save_editing!).ordered

      product.save_editing!(
        product_attributes: creation_product_attributes,
        editions_attributes: [],
        store_infos_attributes: [],
        purchase_attributes: {
          supplier_id: supplier.id,
          amount: "2",
          item_price: "10"
        },
        new_media_images: []
      )
    end
    # rubocop:enable RSpec/MessageSpies

    def creation_product_attributes
      {
        title: "Product with initial purchase",
        sku: "product-with-initial-purchase",
        franchise_id: franchise.id,
        shape_id: shape.id
      }
    end
  end
end
