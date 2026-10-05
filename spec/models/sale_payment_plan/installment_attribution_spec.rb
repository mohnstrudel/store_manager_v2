# frozen_string_literal: true

require "rails_helper"

RSpec.describe SalePaymentPlan do
  describe "#reconcile_installment_attribution!" do
    let(:origin_sale) { create(:sale, shopify_store_id: "gid://shopify/Order/100") }
    let(:follow_up_sale) { create(:sale, shopify_store_id: "gid://shopify/Order/101") }
    let(:placeholder_product) do
      create(:product, shopify_id: Product::SEAL_INSTALLMENT_PLACEHOLDER_SHOPIFY_ID, non_catalog: true)
    end
    let!(:payment_item) { create(:sale_item, sale: follow_up_sale, product: placeholder_product) }

    def build_plan(external_origin_order_id: "100")
      SalePaymentPlan.reconcile!(
        attributes: {
          provider: "seal",
          external_id: "subscription-1",
          external_origin_order_id:,
          kind: "installments",
          status: "active",
          expected_parts: 2,
          synced_at: Time.current
        },
        parts: [
          {sequence: 1, provider_part_id: "origin", external_order_id: external_origin_order_id},
          {sequence: 2, provider_part_id: "attempt-1", external_order_id: "101"}
        ]
      )
    end

    context "with exactly one eligible catalog, non-installment origin item" do
      it "assigns that item, its product, and its variant to the payment item" do
        real_product = create(:product)
        real_variant = create(:variant, product: real_product)
        origin_item = create(:sale_item, sale: origin_sale, product: real_product, variant: real_variant)
        plan = build_plan

        plan.reconcile_installment_attribution!

        expect(payment_item.reload).to have_attributes(
          product: real_product,
          variant: real_variant,
          origin_sale_item: origin_item
        )
      end
    end

    context "with no eligible origin items" do
      it "leaves the payment item generic and unassigned" do
        plan = build_plan

        plan.reconcile_installment_attribution!

        expect(payment_item.reload).to have_attributes(
          product: placeholder_product,
          origin_sale_item: nil,
          variant: placeholder_product.base_variant
        )
      end
    end

    context "with multiple eligible origin items" do
      it "leaves the payment item generic and unassigned" do
        create(:sale_item, sale: origin_sale, product: create(:product))
        create(:sale_item, sale: origin_sale, product: create(:product))
        plan = build_plan

        plan.reconcile_installment_attribution!

        expect(payment_item.reload).to have_attributes(product: placeholder_product, origin_sale_item: nil)
      end
    end

    context "when the origin sale has not been imported locally" do
      it "leaves the payment item generic and unassigned" do
        plan = build_plan(external_origin_order_id: "999")

        plan.reconcile_installment_attribution!

        expect(payment_item.reload).to have_attributes(product: placeholder_product, origin_sale_item: nil)
      end
    end

    context "when an origin item is not itself catalog merchandise" do
      it "excludes the non-catalog item and leaves the payment item generic and unassigned" do
        create(:sale_item, sale: origin_sale, product: placeholder_product)
        plan = build_plan

        plan.reconcile_installment_attribution!

        expect(payment_item.reload).to have_attributes(product: placeholder_product, origin_sale_item: nil)
      end
    end

    context "when an origin item is itself an installment payment" do
      it "excludes it as ineligible and leaves the payment item generic and unassigned" do
        other_real_item = create(:sale_item, product: create(:product))
        create(:sale_item, sale: origin_sale, product: create(:product), origin_sale_item: other_real_item)
        plan = build_plan

        plan.reconcile_installment_attribution!

        expect(payment_item.reload).to have_attributes(product: placeholder_product, origin_sale_item: nil)
      end
    end

    it "corrects a previous wrong guess once the origin resolves uniquely" do
      wrong_product = create(:product)
      wrong_origin_item = create(:sale_item, product: wrong_product)
      payment_item.apply_installment_origin!(wrong_origin_item)
      real_product = create(:product)
      origin_item = create(:sale_item, sale: origin_sale, product: real_product)
      plan = build_plan

      plan.reconcile_installment_attribution!

      expect(payment_item.reload).to have_attributes(product: real_product, origin_sale_item: origin_item)
    end

    it "clears an unsupported guess once the origin becomes ambiguous" do
      real_product = create(:product)
      origin_item = create(:sale_item, sale: origin_sale, product: real_product)
      plan = build_plan
      plan.reconcile_installment_attribution!
      expect(payment_item.reload.origin_sale_item).to eq(origin_item)

      create(:sale_item, sale: origin_sale, product: create(:product))

      plan.reconcile_installment_attribution!

      expect(payment_item.reload).to have_attributes(product: placeholder_product, origin_sale_item: nil)
    end

    it "converges without change across repeated runs" do
      real_product = create(:product)
      origin_item = create(:sale_item, sale: origin_sale, product: real_product)
      plan = build_plan
      plan.reconcile_installment_attribution!

      expect {
        3.times { plan.reconcile_installment_attribution! }
      }.not_to change(SaleItem, :count)

      expect(payment_item.reload).to have_attributes(product: real_product, origin_sale_item: origin_item)
    end

    it "constructs no Shopify or Seal client" do
      expect(Shopify::Api::Client).not_to receive(:new)
      expect(Seal::Api::Client).not_to receive(:new)

      create(:sale_item, sale: origin_sale, product: create(:product))
      build_plan.reconcile_installment_attribution!
    end
  end
end
