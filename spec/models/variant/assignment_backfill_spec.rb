# frozen_string_literal: true

require "rails_helper"

RSpec.describe Variant::AssignmentBackfill do
  describe ".call" do
    it "defaults to dry-run unless APPLY is exactly 1" do
      product = create(:product)
      purchase = create(:purchase, product:)
      purchase.update_columns(variant_id: nil)
      dry_run_output = StringIO.new

      described_class.call(env: {}, output: dry_run_output)
      described_class.call(env: {"APPLY" => "true"}, output: StringIO.new)

      expect(purchase.reload.variant_id).to be_nil
      expect(dry_run_output.string).to include("mode=dry-run")

      described_class.call(env: {"APPLY" => "1"}, output: StringIO.new)

      expect(purchase.reload.variant_id).to eq(product.base_variant.id)
    end
  end

  describe "#call" do
    it "recalculates counts, checkpoints each phase, and is idempotent" do
      base_only_product = create(:product)
      purchase = create(:purchase, product: base_only_product)
      sale_item = create(:sale_item, product: base_only_product)
      purchase_item = create(:purchase_item, purchase:)
      purchase.update_columns(variant_id: nil)
      sale_item.update_columns(variant_id: nil)
      purchase_item.update_columns(product_id: nil, variant_id: nil)
      option_product = create(:product)
      create(:variant, :with_version, product: option_product)
      option_product.base_variant.update_columns(deactivated_at: nil)
      output = StringIO.new

      result = described_class.new(apply: true, output:).call

      aggregate_failures do
        expect(result.failures).to be_empty
        expect(result.before_counts).to include(
          purchases: 1,
          sale_items: 1,
          purchase_item_purchase_identity: 1,
          base_activation: 1
        )
        expect(result.after_counts).to include(
          purchases: 0,
          sale_items: 0,
          purchase_item_purchase_identity: 0,
          base_activation: 0
        )
        expect(purchase.reload.variant_id).to eq(base_only_product.base_variant.id)
        expect(sale_item.reload.variant_id).to eq(base_only_product.base_variant.id)
        expect(purchase_item.reload).to have_attributes(
          product_id: base_only_product.id,
          variant_id: base_only_product.base_variant.id
        )
        expect(option_product.base_variant.reload).to be_deactivated
        expect(output.string).to include(
          "CHECKPOINT phase=sync_base_activation",
          "CHECKPOINT phase=audit"
        )
      end

      rerun = described_class.new(apply: true, output: StringIO.new).call

      expect(rerun.phase_counts.values.sum { |counts| counts.fetch(:repaired, 0) }).to eq(0)
    end

    it "resumes after a logged record id without repeating earlier records" do
      product = create(:product)
      first = create(:purchase, product:)
      second = create(:purchase, product:)
      first.update_columns(variant_id: nil)
      second.update_columns(variant_id: nil)
      output = StringIO.new

      described_class.new(
        apply: true,
        output:,
        resume_from: :repair_purchases,
        after_id: first.id
      ).call

      aggregate_failures do
        expect(first.reload.variant_id).to be_nil
        expect(second.reload.variant_id).to eq(product.base_variant.id)
        expect(output.string).to include(
          "RESUME phase=repair_purchases after_id=#{first.id}",
          "CHECKPOINT phase=repair_purchases last_id=#{second.id}"
        )
      end
    end

    it "orders Shopify checkpoints by the numeric StoreInfo id used by AFTER_ID" do
      first_group = [
        create(:variant).shopify_info,
        create(:variant).shopify_info
      ]
      first_group.first.update!(
        store_id: "gid://shopify/ProductVariant/z-last",
        pull_time: 1.day.ago
      )
      first_group.second.update!(
        store_id: "gid://shopify/ProductVariant/z-last",
        pull_time: nil
      )
      second_group = [
        create(:variant).shopify_info,
        create(:variant).shopify_info
      ]
      second_group.first.update!(
        store_id: "gid://shopify/ProductVariant/a-first",
        pull_time: 1.day.ago
      )
      second_group.second.update!(
        store_id: "gid://shopify/ProductVariant/a-first",
        pull_time: nil
      )
      expected_ids = [
        first_group.pluck(:id).min,
        second_group.pluck(:id).min
      ]
      output = StringIO.new

      described_class.new(
        apply: false,
        output:,
        batch_size: 1
      ).call

      checkpoint_ids = output.string
        .scan(
          /CHECKPOINT phase=reconcile_shopify_identity last_id=(\d+)/
        )
        .flatten
        .map(&:to_i)

      expect(checkpoint_ids).to eq(expected_ids.sort)
    end

    it "halts at a mutation failure and resumes after the last completed id" do
      product = create(:product)
      first = create(:purchase, product:)
      failed = create(:purchase, product:)
      later = create(:purchase, product:)
      [first, failed, later].each { |purchase| purchase.update_columns(variant_id: nil) }
      repair = Variant::AssignmentRepair.new
      fail_once = true
      allow(repair).to receive(:repair_purchase!).and_wrap_original do |original, **arguments|
        if arguments.fetch(:purchase_id) == failed.id && fail_once
          fail_once = false
          raise ActiveRecord::Deadlocked, "retry this record"
        end

        original.call(**arguments)
      end
      output = StringIO.new

      failed_run = described_class.new(
        apply: true,
        output:,
        resume_from: :repair_purchases,
        repair:
      ).call

      aggregate_failures do
        expect(first.reload.variant_id).to eq(product.base_variant.id)
        expect(failed.reload.variant_id).to be_nil
        expect(later.reload.variant_id).to be_nil
        expect(failed_run.failures).to contain_exactly(
          include(
            phase: :repair_purchases,
            id: failed.id,
            error_class: "ActiveRecord::Deadlocked"
          )
        )
        expect(output.string).to include(
          "CHECKPOINT phase=repair_purchases last_id=#{first.id}",
          "HALTED phase=repair_purchases failed_id=#{failed.id} resume_after_id=#{first.id}"
        )
        expect(output.string).not_to include(
          "CHECKPOINT phase=repair_purchases last_id=#{failed.id}",
          "CHECKPOINT phase=repair_purchases last_id=#{later.id}",
          "CHECKPOINT phase=repair_sale_items"
        )
      end

      resumed_run = described_class.new(
        apply: true,
        output: StringIO.new,
        resume_from: :repair_purchases,
        after_id: first.id,
        repair:
      ).call

      aggregate_failures do
        expect(resumed_run.failures).to be_empty
        expect(failed.reload.variant_id).to eq(product.base_variant.id)
        expect(later.reload.variant_id).to eq(product.base_variant.id)
      end
    end

    it "repairs only proof-backed SaleItem identity and leaves ambiguous rows live" do
      product = create(:product)
      only_real_variant = create(:variant, :with_version, product:)
      provable = create(:sale_item, product:, variant: only_real_variant)
      provable.update_columns(variant_id: nil)
      origin = create(:sale_item, product:, variant: only_real_variant)
      installment = create(
        :sale_item,
        product:,
        variant: only_real_variant,
        origin_sale_item: origin
      )
      installment.update_columns(variant_id: nil)
      ambiguous_product = create(:product)
      first_ambiguous_variant = create(
        :variant,
        :with_version,
        product: ambiguous_product,
        version_value: "One"
      )
      create(:variant, :with_color, product: ambiguous_product, color_value: "Two")
      ambiguous = create(
        :sale_item,
        product: ambiguous_product,
        variant: first_ambiguous_variant
      )
      ambiguous.update_columns(variant_id: nil)

      result = described_class.new(apply: true, output: StringIO.new).call

      aggregate_failures do
        expect(provable.reload.variant_id).to eq(only_real_variant.id)
        expect(installment.reload).to have_attributes(
          product_id: origin.product_id,
          variant_id: origin.variant_id
        )
        expect(ambiguous.reload.variant_id).to be_nil
        expect(Variant::AssignmentIntegrity.new.broken_sale_items).to include(ambiguous)
        expect(result.phase_counts.fetch(:repair_sale_items)).to include(
          repaired: 2,
          unresolved: 1
        )
        expect(
          result.phase_counts.dig(:repair_sale_items, :reasons)
        ).to include(
          origin_installment: 1,
          single_real_variant: 1,
          ambiguous_option_product: 1
        )
      end
    end

    it "reconciles a duplicate Shopify identity from unique pull provenance atomically" do
      stale_product = create(:product)
      canonical_product = create(:product)
      stale_variant = create(:variant, :with_version, product: stale_product)
      canonical_variant = create(:variant, :with_color, product: canonical_product)
      duplicate_store_id = "gid://shopify/ProductVariant/123"
      stale_variant.shopify_info.update!(
        store_id: duplicate_store_id,
        pull_time: nil,
        ext_created_at: nil,
        ext_updated_at: nil
      )
      canonical_variant.shopify_info.update!(
        store_id: duplicate_store_id,
        pull_time: 1.day.ago,
        ext_created_at: 2.days.ago
      )
      mismatched = create(
        :sale_item,
        product: canonical_product,
        variant: canonical_variant
      )
      mismatched.update_columns(variant_id: stale_variant.id)
      historical = create(
        :sale_item,
        product: stale_product,
        variant: stale_variant
      )

      result = described_class.new(apply: true, output: StringIO.new).call

      aggregate_failures do
        expect(result.phase_counts.fetch(:reconcile_shopify_identity)).to include(
          repaired: 1,
          unresolved: 0
        )
        expect(canonical_variant.reload.shopify_store_id).to eq(duplicate_store_id)
        expect(stale_variant.reload.shopify_info).to be_nil
        expect(mismatched.reload.variant_id).to eq(canonical_variant.id)
        expect(historical.reload.variant_id).to eq(stale_variant.id)
        expect(
          StoreInfo.shopify.where(
            storable_type: "Variant",
            store_id: duplicate_store_id
          ).count
        ).to eq(1)
      end
    end

    it "reports unresolved duplicate identity without mutating it" do
      first = create(:variant)
      second = create(:variant)
      duplicate_store_id = "gid://shopify/ProductVariant/unproven"
      first.shopify_info.update!(store_id: duplicate_store_id, pull_time: nil)
      second.shopify_info.update!(store_id: duplicate_store_id, pull_time: nil)
      output = StringIO.new

      result = described_class.new(apply: true, output:).call

      aggregate_failures do
        expect(result.phase_counts.fetch(:reconcile_shopify_identity)).to include(
          repaired: 0,
          unresolved: 1
        )
        expect(
          StoreInfo.shopify.where(
            storable_type: "Variant",
            store_id: duplicate_store_id
          ).count
        ).to eq(2)
        expect(output.string).to include(
          "UNRESOLVED phase=reconcile_shopify_identity",
          duplicate_store_id
        )
      end
    end

    it "backfills every PurchaseItem identity and silently exact-relinks" do
      product = create(:product)
      other_product = create(:product)
      purchase = create(:purchase, product:)
      wrong_sale_item = create(:sale_item, product: other_product, qty: 1)
      exact_sale_item = create(:sale_item, product:, qty: 1)
      purchase_item = create(:purchase_item, purchase:)
      purchase_item.update_columns(
        product_id: other_product.id,
        variant_id: other_product.base_variant.id,
        sale_item_id: wrong_sale_item.id
      )
      allow(PurchaseItem).to receive(:notify_order_status!)

      described_class.new(apply: true, output: StringIO.new).call

      aggregate_failures do
        expect(purchase_item.reload).to have_attributes(
          product_id: product.id,
          variant_id: product.base_variant.id,
          sale_item_id: exact_sale_item.id
        )
        expect(PurchaseItem).not_to have_received(:notify_order_status!)
        expect(
          Variant::AssignmentIntegrity.new.purchase_item_purchase_identity_mismatches
        ).to be_empty
      end
    end

    it "does not call Woo, Shopify, or Seal network clients" do
      expect(Woo::PullSalesJob).not_to receive(:new)
      expect(Shopify::Api::Client).not_to receive(:new)
      expect(Seal::Api::Client).not_to receive(:shared)

      described_class.new(apply: true, output: StringIO.new).call
    end
  end
end
