# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_items
#
#  id                   :bigint           not null, primary key
#  expected_revenue     :decimal(8, 2)
#  outstanding_revenue  :decimal(8, 2)
#  price                :decimal(8, 2)
#  purchase_items_count :integer          default(0), not null
#  qty                  :integer
#  received_revenue     :decimal(8, 2)
#  refunded_revenue     :decimal(8, 2)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  origin_sale_item_id  :bigint
#  product_id           :bigint           not null
#  sale_id              :bigint           not null
#  shopify_id           :string
#  shopify_variant_id   :string
#  variant_id           :bigint
#  woo_id               :string
#
require "rails_helper"

RSpec.describe SaleItem do
  describe "#apply_installment_origin" do
    let(:placeholder_product) do
      create(:product, shopify_id: Product::SEAL_INSTALLMENT_PLACEHOLDER_SHOPIFY_ID, non_catalog: true)
    end
    let(:payment_item) { create(:sale_item, product: placeholder_product) }

    it "assigns the origin item's product, variant, and identity" do
      real_product = create(:product)
      real_variant = create(:variant, product: real_product)
      origin_item = create(:sale_item, product: real_product, variant: real_variant)

      payment_item.apply_installment_origin(origin_item)

      expect(payment_item.reload).to have_attributes(
        product: real_product,
        variant: real_variant,
        origin_sale_item: origin_item
      )
    end

    it "assigns a real variant the origin bought even after that variant is later deactivated" do
      real_product = create(:product)
      real_variant = create(:variant, product: real_product)
      create(:variant, product: real_product, sku: "still-active-sku")
      origin_item = create(:sale_item, product: real_product, variant: real_variant)
      real_variant.remove_or_deactivate

      payment_item.apply_installment_origin(origin_item)

      expect(payment_item.reload).to have_attributes(product: real_product, variant: real_variant)
    end

    it "restores the placeholder product and clears the origin when given nil" do
      real_product = create(:product)
      origin_item = create(:sale_item, product: real_product)
      payment_item.apply_installment_origin(origin_item)

      payment_item.apply_installment_origin(nil)

      expect(payment_item.reload).to have_attributes(product: placeholder_product, origin_sale_item: nil)
    end

    it "never links or notifies about a warehouse unit even when one is available for the new product" do
      real_product = create(:product)
      real_variant = create(:variant, product: real_product)
      origin_item = create(:sale_item, product: real_product, variant: real_variant)
      available_purchase_item = create(
        :purchase_item,
        purchase: create(:purchase, product: real_product, variant: real_variant)
      )

      expect(NotificationsMailer).not_to receive(:order_status_updated_email)

      payment_item.apply_installment_origin(origin_item)

      expect(available_purchase_item.reload.sale_item_id).to be_nil
      expect(payment_item.reload.purchase_items).to be_empty
    end

    it "keeps the change in the sale item's own audit history" do
      real_product = create(:product)
      origin_item = create(:sale_item, product: real_product)

      expect { payment_item.apply_installment_origin(origin_item) }.to change { payment_item.audits.count }.by(1)
    end
  end

  describe "Shopify variant link" do
    let(:shopify_variant_id) { "gid://shopify/ProductVariant/50971387363657" }
    let(:product) { create(:product) }

    it "is unlinked when no local variant carries the line's Shopify variant" do
      sale_item = create(:sale_item, product:, shopify_variant_id:)

      expect(sale_item).to be_shopify_variant_unlinked
      expect(described_class.shopify_variant_unlinked).to contain_exactly(sale_item)
    end

    it "is linked once a local variant carries the line's Shopify variant" do
      sale_item = create(:sale_item, product:, shopify_variant_id:)
      create(:variant, product:, shopify_store_id: shopify_variant_id)

      expect(sale_item.reload).not_to be_shopify_variant_unlinked
      expect(described_class.shopify_variant_unlinked).to be_empty
    end

    it "is unlinked when only a record that is not a variant carries the Shopify ID" do
      sale_item = create(:sale_item, product:, shopify_variant_id:)
      create(:store_info, :shopify, storable: product, store_id: shopify_variant_id)

      expect(sale_item.reload).to be_shopify_variant_unlinked
      expect(described_class.shopify_variant_unlinked).to contain_exactly(sale_item)
    end

    it "is neither unlinked nor in the scope without a Shopify variant ID" do
      sale_item = create(:sale_item, product:, shopify_variant_id: nil)

      expect(sale_item).not_to be_shopify_variant_unlinked
      expect(described_class.shopify_variant_unlinked).to be_empty
    end

    it "answers from a preloaded link without querying" do
      create(:sale_item, product:, shopify_variant_id:)
      sale_item = described_class.includes(:shopify_variant_info).sole
      queries = []
      subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| queries << payload[:sql] }

      sale_item.shopify_variant_unlinked?

      expect(queries).to be_empty
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end

    it "writes no audit when only the Shopify variant ID changes" do
      sale_item = create(:sale_item)

      expect { sale_item.update!(shopify_variant_id: "gid://shopify/ProductVariant/1") }
        .not_to change { sale_item.audits.count }
    end
  end
end
