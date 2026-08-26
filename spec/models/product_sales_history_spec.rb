# frozen_string_literal: true

require "rails_helper"

RSpec.describe Product do
  describe "#active_sale_items" do
    let(:product) { create(:product) }
    let(:variant) { create(:variant, product:) }
    let(:warehouse) { create(:warehouse) }
    let(:supplier) { create(:supplier) }

    let!(:older_active_sale_item) do
      sale = create(:sale, status: "processing")
      create(:sale_address, sale:, kind: :shipping)
      sale_item = create(:sale_item,
        product:,
        variant:,
        sale:,
        qty: 2,
        created_at: 2.days.ago,
        updated_at: 2.days.ago)
      create(:purchase_item,
        sale_item:,
        purchase: create(:purchase, product:, variant:, supplier:),
        warehouse:)
      sale_item
    end

    let!(:newer_active_sale_item) do
      sale = create(:sale, status: "pre-ordered")
      create(:sale_address, sale:, kind: :shipping)
      sale_item = create(:sale_item,
        product:,
        variant:,
        sale:,
        qty: 1,
        created_at: 1.day.ago,
        updated_at: 1.day.ago)
      create(:purchase_item,
        sale_item:,
        purchase: create(:purchase, product:, variant:, supplier:),
        warehouse:)
      sale_item
    end

    it "returns active sale items ordered by creation time" do
      expect(product.active_sale_items).to eq([older_active_sale_item, newer_active_sale_item])
    end

    it "preloads the full history tree for the active sales table" do
      product.active_sale_items.each do |sale_item|
        sale_association = sale_item.association(:sale)
        purchase_items_association = sale_item.association(:purchase_items)

        aggregate_failures do
          expect(sale_association).to be_loaded
          expect(sale_item.association(:product)).to be_loaded
          expect(sale_item.association(:variant)).to be_loaded
          expect(purchase_items_association).to be_loaded

          sale = sale_association.target
          purchase_item = purchase_items_association.target.first

          expect(sale.association(:customer)).to be_loaded
          expect(sale.association(:shopify_info)).to be_loaded
          expect(sale.association(:woo_info)).to be_loaded
          expect(sale.association(:shipping_address)).to be_loaded
          expect(purchase_item.association(:warehouse)).to be_loaded
        end
      end
    end
  end

  describe "#completed_sale_items" do
    let(:product) { create(:product) }
    let(:variant) { create(:variant, product:) }
    let(:warehouse) { create(:warehouse) }
    let(:supplier) { create(:supplier) }

    let!(:completed_sale_item) do
      sale = create(:sale, status: "completed")
      create(:sale_address, sale:, kind: :shipping)
      sale_item = create(:sale_item,
        product:,
        variant:,
        sale:,
        qty: 4,
        created_at: 1.day.ago,
        updated_at: 1.day.ago)
      create(:purchase_item,
        sale_item:,
        purchase: create(:purchase, product:, variant:, supplier:),
        warehouse:)
      sale_item
    end

    it "returns completed sale items ordered by creation time" do
      expect(product.completed_sale_items).to eq([completed_sale_item])
    end

    it "preloads the full history tree for the completed sales table" do
      sale_item = product.completed_sale_items.first
      sale_association = sale_item.association(:sale)
      purchase_items_association = sale_item.association(:purchase_items)

      aggregate_failures do
        expect(sale_association).to be_loaded
        expect(sale_item.association(:product)).to be_loaded
        expect(sale_item.association(:variant)).to be_loaded
        expect(purchase_items_association).to be_loaded

        sale = sale_association.target
        purchase_item = purchase_items_association.target.first

        expect(sale.association(:customer)).to be_loaded
        expect(sale.association(:shopify_info)).to be_loaded
        expect(sale.association(:woo_info)).to be_loaded
        expect(sale.association(:shipping_address)).to be_loaded
        expect(purchase_item.association(:warehouse)).to be_loaded
      end
    end
  end

  describe "follow-up payment role" do
    let(:product) { create(:product) }
    let(:variant) { create(:variant, product:) }

    it "keeps a Seal follow-up out of active merchandise history and puts it in the active payment group" do
      origin_item = create_history_sale_item(product:, variant:, status: "processing", shopify_store_id: "gid://shopify/Order/900")
      follow_up_item = create_history_sale_item(product:, variant:, status: "processing", shopify_store_id: "gid://shopify/Order/901")
      create_plan(
        external_origin_order_id: "900",
        parts: [
          {sequence: 1, provider_part_id: "part-1", external_order_id: "900"},
          {sequence: 2, provider_part_id: "part-2", external_order_id: "901"}
        ]
      )

      expect(product.active_sale_items).to contain_exactly(origin_item)
      expect(product.active_payment_items).to contain_exactly(follow_up_item)
    end

    it "keeps a Seal follow-up out of completed merchandise history and puts it in the completed payment group" do
      create_history_sale_item(product:, variant:, status: "processing", shopify_store_id: "gid://shopify/Order/910")
      follow_up_item = create_history_sale_item(product:, variant:, status: "completed", shopify_store_id: "gid://shopify/Order/911")
      create_plan(
        external_id: "subscription-2",
        external_origin_order_id: "910",
        parts: [
          {sequence: 1, provider_part_id: "part-3", external_order_id: "910"},
          {sequence: 2, provider_part_id: "part-4", external_order_id: "911"}
        ]
      )

      expect(product.completed_sale_items).to eq([])
      expect(product.completed_payment_items).to contain_exactly(follow_up_item)
    end

    it "keeps the deposit origin order a merchandise sale, never a payment" do
      origin_item = create_history_sale_item(product:, variant:, status: "processing", shopify_store_id: "gid://shopify/Order/920")
      create_plan(
        kind: "deposit",
        external_id: "subscription-3",
        external_origin_order_id: "920",
        parts: [{sequence: 1, provider_part_id: "part-5", external_order_id: "920"}]
      )

      expect(product.active_sale_items).to contain_exactly(origin_item)
      expect(product.active_payment_items).to eq([])
    end

    it "keeps every schedule of a Shopify same-order payment_terms plan as merchandise" do
      item = create_history_sale_item(product:, variant:, status: "processing", shopify_store_id: "gid://shopify/Order/930")
      create_plan(
        provider: "shopify",
        kind: "payment_terms",
        external_id: "terms-1",
        external_origin_order_id: "930",
        parts: [
          {sequence: 1, provider_part_id: "sched-1", external_order_id: "930"},
          {sequence: 2, provider_part_id: "sched-2", external_order_id: "930"}
        ]
      )

      expect(product.active_sale_items).to contain_exactly(item)
      expect(product.active_payment_items).to eq([])
    end

    it "does not duplicate product quantity or cost when a merchandise sale has several follow-up payments" do
      origin_item = create_history_sale_item(product:, variant:, status: "processing", shopify_store_id: "gid://shopify/Order/940", qty: 2)
      create_history_sale_item(product:, variant:, status: "processing", shopify_store_id: "gid://shopify/Order/941")
      create_history_sale_item(product:, variant:, status: "processing", shopify_store_id: "gid://shopify/Order/942")
      create_plan(
        external_id: "subscription-4",
        external_origin_order_id: "940",
        parts: [
          {sequence: 1, provider_part_id: "part-6", external_order_id: "940"},
          {sequence: 2, provider_part_id: "part-7", external_order_id: "941"},
          {sequence: 3, provider_part_id: "part-8", external_order_id: "942"}
        ]
      )

      expect(product.active_sale_items).to contain_exactly(origin_item)
      expect(product.variant_sales_sums).to eq(variant.id => 2)
    end
  end

  describe "#variant_sales_sums" do
    let(:product) { create(:product) }
    let(:primary_variant) { create(:variant, product:) }
    let(:secondary_variant) { create(:variant, product:) }

    before do
      create(:sale_item, product:, variant: primary_variant, sale: create(:sale, status: "processing"), qty: 2)
      create(:sale_item, product:, variant: primary_variant, sale: create(:sale, status: "completed"), qty: 9)
      create(:sale_item, product:, variant: secondary_variant, sale: create(:sale, status: "partially-paid"), qty: 5)
    end

    it "sums active sale quantities per variant" do
      expect(product.variant_sales_sums).to eq(
        primary_variant.id => 2,
        secondary_variant.id => 5
      )
    end

    it "excludes a Seal follow-up payment from the sold quantity" do
      origin_sale = create(:sale, status: "processing", shopify_store_id: "gid://shopify/Order/950")
      follow_up_sale = create(:sale, status: "processing", shopify_store_id: "gid://shopify/Order/951")
      create(:sale_item, product:, variant: primary_variant, sale: origin_sale, qty: 3)
      create(:sale_item, product:, variant: primary_variant, sale: follow_up_sale, qty: 3)
      create_plan(
        external_id: "subscription-5",
        external_origin_order_id: "950",
        parts: [
          {sequence: 1, provider_part_id: "part-9", external_order_id: "950"},
          {sequence: 2, provider_part_id: "part-10", external_order_id: "951"}
        ]
      )

      expect(product.variant_sales_sums).to eq(
        primary_variant.id => 5,
        secondary_variant.id => 5
      )
    end
  end

  describe "#variant_purchase_sums" do
    let(:product) { create(:product) }
    let(:primary_variant) { create(:variant, product:) }
    let(:secondary_variant) { create(:variant, product:) }

    before do
      create(:purchase, product:, variant: primary_variant, amount: 3, item_price: 10)
      create(:purchase, product:, variant: primary_variant, amount: 2, item_price: 10)
      create(:purchase, product:, variant: secondary_variant, amount: 7, item_price: 10)
    end

    it "sums purchase amounts per variant" do
      expect(product.variant_purchase_sums).to eq(
        primary_variant.id => 5,
        secondary_variant.id => 7
      )
    end
  end

  describe "#variant_purchase_cost_totals" do
    let(:product) { create(:product) }
    let(:primary_variant) { create(:variant, product:) }
    let(:secondary_variant) { create(:variant, product:) }

    before do
      primary_purchase = create(:purchase, product:, variant: primary_variant, item_price: BigDecimal(10))
      create(:purchase_item, :with_direct_expense, purchase: primary_purchase, shipping_cost: BigDecimal(2), direct_expense_amount: BigDecimal(1))
      create(:purchase_item, purchase: primary_purchase, shipping_cost: BigDecimal(3), expenses: BigDecimal(0))

      secondary_purchase = create(:purchase, product:, variant: secondary_variant, item_price: BigDecimal(20))
      create(:purchase_item, :with_direct_expense, purchase: secondary_purchase, shipping_cost: BigDecimal(5), direct_expense_amount: BigDecimal(2))
    end

    it "sums item price, shipping cost, and direct expenses per variant" do
      expect(product.variant_purchase_cost_totals).to eq(
        primary_variant.id => {cost: BigDecimal(26), units: 2},
        secondary_variant.id => {cost: BigDecimal(27), units: 1}
      )
    end

    it "counts one unit per purchase item so the cost can be averaged back" do
      totals = product.variant_purchase_cost_totals.fetch(primary_variant.id)

      expect(totals[:cost] / totals[:units]).to eq(BigDecimal(13))
    end

    it "omits variants without linked purchase items" do
      untouched_variant = create(:variant, product:)

      expect(product.variant_purchase_cost_totals).not_to have_key(untouched_variant.id)
    end
  end

  def create_plan(parts:, external_origin_order_id:, provider: "seal", kind: "installments", external_id: "subscription-1")
    SalePaymentPlan.reconcile!(
      attributes: {
        provider:,
        external_id:,
        external_origin_order_id:,
        kind:,
        status: "active",
        expected_parts: parts.size,
        synced_at: Time.current
      },
      parts:
    )
  end

  def create_history_sale_item(product:, variant:, status:, shopify_store_id:, qty: 1)
    sale = create(:sale, status:, shopify_store_id:)
    create(:sale_item, product:, variant:, sale:, qty:)
  end
end
