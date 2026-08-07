# frozen_string_literal: true

require "rails_helper"

RSpec.describe "PurchaseItem identity reconciliation" do
  let(:product) { create(:product) }
  let(:variant_a) { create(:variant, :with_version, product:, version_value: "A") }
  let(:variant_b) { create(:variant, :with_version, product:, version_value: "B") }
  let(:active_sale) { create(:sale, status: Sale.active_status_names.first) }

  before do
    variant_a
    variant_b
  end

  it "unlinks before a Purchase identity change, copies identity, and exact-relinks" do
    purchase_a = create(:purchase, product:, variant: variant_a)
    purchase_b = create(:purchase, product:, variant: variant_b)
    old_sale_item = create(:sale_item, sale: active_sale, product:, variant: variant_a)
    new_sale_item = create(:sale_item, sale: active_sale, product:, variant: variant_b)
    purchase_item = create(:purchase_item, purchase: purchase_a, sale_item: old_sale_item)
    create(:purchase_item, purchase: purchase_b)
    callbacks = []
    allow(ActiveRecord).to receive(:after_all_transactions_commit) { |&callback| callbacks << callback }
    allow(PurchaseItem).to receive(:notify_order_status!)

    purchase_a.update!(variant: variant_b)

    aggregate_failures do
      expect(purchase_item.reload).to have_attributes(
        product_id: product.id,
        variant_id: variant_b.id,
        sale_item_id: new_sale_item.id
      )
      expect(old_sale_item.reload.purchase_items_count).to eq(0)
      expect(callbacks.size).to eq(1)
    end

    callbacks.first.call
    expect(PurchaseItem).to have_received(:notify_order_status!).with(
      purchase_item_ids: [purchase_item.id]
    )
  end

  it "leaves an incompatible PurchaseItem unlinked when exact capacity is unavailable" do
    purchase = create(:purchase, product:, variant: variant_a)
    old_sale_item = create(:sale_item, sale: active_sale, product:, variant: variant_a)
    purchase_item = create(:purchase_item, purchase:, sale_item: old_sale_item)

    purchase.update!(variant: variant_b)

    expect(purchase_item.reload).to have_attributes(
      variant_id: variant_b.id,
      sale_item_id: nil
    )
  end

  it "unlinks before a SaleItem identity change and exact-relinks available inventory" do
    purchase_a = create(:purchase, product:, variant: variant_a)
    purchase_b = create(:purchase, product:, variant: variant_b)
    sale_item = create(:sale_item, sale: active_sale, product:, variant: variant_a)
    old_purchase_item = create(:purchase_item, purchase: purchase_a, sale_item:)
    new_purchase_item = create(:purchase_item, purchase: purchase_b)
    callbacks = []
    allow(ActiveRecord).to receive(:after_all_transactions_commit) { |&callback| callbacks << callback }

    sale_item.update!(variant: variant_b)

    aggregate_failures do
      expect(old_purchase_item.reload.sale_item_id).to be_nil
      expect(new_purchase_item.reload.sale_item_id).to eq(sale_item.id)
      expect(callbacks.size).to eq(1)
    end
  end
end
