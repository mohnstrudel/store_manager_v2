# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Variant assignment issues" do
  before { sign_in_as_admin }

  describe "GET /variant_assignment_issues" do
    it "renders live counters, evidence, impact, and historical repair candidates" do
      product = create(:product)
      active_variant = create(:variant, :with_version, product:, version_value: "Active")
      historical_variant = create(:variant, :with_color, product:, color_value: "Archive")
      purchase = create(:purchase, product:, variant: active_variant, order_reference: "BROKEN-42")
      create(:purchase_item, purchase:)
      historical_variant.update!(deactivated_at: Time.current)
      purchase.update_columns(variant_id: nil)

      get variant_assignment_issues_path

      expect(response).to have_http_status(:ok)
      expect_inertia.to render_component("VariantAssignmentIssues/Index")
      expect_inertia.to have_props(
        issue_type: "purchases",
        filter: "",
        counts: {
          purchases: 1,
          sale_items: 0,
          purchase_item_links: 0
        }
      )
      issue = inertia.props[:issues].sole
      aggregate_failures do
        expect(issue).to include(
          id: purchase.id,
          reference: "BROKEN-42",
          reason: "missing_variant",
          product_title: product.full_title,
          current_variant_label: "Missing Variant",
          inventory_units: 1,
          linked_units: 0
        )
        expect(issue[:candidates]).to contain_exactly(
          {value: active_variant.id, label: active_variant.assignment_label, base_model: false},
          {value: historical_variant.id, label: historical_variant.assignment_label, base_model: false}
        )
      end
    end

    it "keeps the selected tab, reason filter, and page in the URL-backed contract" do
      product = create(:product)
      26.times do
        sale_item = create(:sale_item, product:)
        sale_item.update_columns(variant_id: nil)
      end

      get variant_assignment_issues_path, params: {
        issue_type: "sale_items",
        reason: "missing_variant",
        page: 2
      }

      expect_inertia.to have_props(
        issue_type: "sale_items",
        filter: "missing_variant",
        pagination: {
          current_page: 2,
          total_pages: 2,
          total_count: 26,
          limit: 25
        }
      )
      expect(inertia.props[:issues].size).to eq(1)
    end

    it "shows live link evidence and replacement impact" do
      original_product = create(:product)
      target_product = create(:product)
      mismatch = create(
        :purchase_item,
        purchase: create(:purchase, product: original_product),
        sale_item: create(:sale_item, product: original_product, qty: 2)
      )
      exact_inventory = create(
        :purchase_item,
        purchase: create(:purchase, product: target_product)
      )
      mismatch.sale_item.update_columns(
        product_id: target_product.id,
        variant_id: target_product.base_variant.id
      )

      get variant_assignment_issues_path, params: {
        issue_type: "purchase_item_links"
      }

      issue = inertia.props[:issues].sole
      aggregate_failures do
        expect(issue).to include(
          id: mismatch.id,
          reason: "sale_item_identity",
          purchase_id: mismatch.purchase_id,
          sale_item_id: mismatch.sale_item_id,
          exact_replacements_available: 1,
          remaining_capacity_after_unlink: 2
        )
        expect(issue[:exact_replacement_ids]).to contain_exactly(exact_inventory.id)
      end
    end

    it "denies the page to non-administrators" do
      log_out
      sign_in(create(:user, :manager))

      get variant_assignment_issues_path

      expect(response).to redirect_to(noop_path)
    end
  end

  describe "PATCH /variant_assignment_issues/purchases/:id" do
    it "repairs from historical candidates and returns to the URL-backed view" do
      product = create(:product)
      historical_variant = create(:variant, :with_version, product:)
      purchase = create(:purchase, product:, variant: historical_variant)
      historical_variant.update!(deactivated_at: Time.current)
      purchase.update_columns(variant_id: nil)
      return_to = variant_assignment_issues_path(
        issue_type: "purchases",
        reason: "missing_variant",
        page: 2
      )

      patch variant_assignment_issues_purchase_path(purchase), params: {
        purchase: {variant_id: historical_variant.id},
        return_to:
      }

      aggregate_failures do
        expect(response).to redirect_to(return_to)
        expect(purchase.reload.variant_id).to eq(historical_variant.id)
      end
    end

    it "redirects with an inline error for an invalid candidate" do
      product = create(:product)
      purchase = create(:purchase, product:)
      purchase.update_columns(variant_id: nil)

      patch variant_assignment_issues_purchase_path(purchase), params: {
        purchase: {variant_id: create(:product).base_variant.id},
        return_to: variant_assignment_issues_path
      }

      expect(response).to redirect_to(variant_assignment_issues_path)
      follow_redirect!
      expect(inertia.props[:errors][:variant_id]).to eq(
        "Variant is not an available repair candidate"
      )
    end

    it "accepts a stale already-resolved row as a successful no-op" do
      purchase = create(:purchase)

      patch variant_assignment_issues_purchase_path(purchase), params: {
        purchase: {variant_id: purchase.variant_id},
        return_to: variant_assignment_issues_path
      }

      expect(response).to redirect_to(variant_assignment_issues_path)
      expect(flash[:notice]).to eq("Variant assignment is already repaired")
    end

    it "keeps a concurrently changed unresolved row retryable" do
      purchase = create(:purchase)
      allow(Variant::AssignmentRepair).to receive(:repair_purchase!).and_raise(
        PurchaseItem::Linking::StaleLinkState
      )

      patch variant_assignment_issues_purchase_path(purchase), params: {
        purchase: {variant_id: purchase.variant_id},
        return_to: variant_assignment_issues_path
      }

      expect(response).to redirect_to(variant_assignment_issues_path)
      follow_redirect!
      expect(inertia.props[:errors][:base]).to eq(
        "This issue changed while it was being repaired. Review it and try again"
      )
    end

    it "denies non-administrators without invoking the silent repair command" do
      purchase = create(:purchase)
      log_out
      sign_in(create(:user, :manager))
      allow(Variant::AssignmentRepair).to receive(:repair_purchase!)

      patch variant_assignment_issues_purchase_path(purchase), params: {
        purchase: {variant_id: purchase.variant_id}
      }

      expect(response).to redirect_to(noop_path)
      expect(Variant::AssignmentRepair).not_to have_received(:repair_purchase!)
    end
  end

  describe "PATCH /variant_assignment_issues/sale_items/:id" do
    it "repairs the SaleItem through the silent command" do
      sale_item = create(:sale_item)
      sale_item.update_columns(variant_id: nil)

      patch variant_assignment_issues_sale_item_path(sale_item), params: {
        sale_item: {variant_id: sale_item.product.base_variant.id},
        return_to: variant_assignment_issues_path(issue_type: "sale_items")
      }

      expect(sale_item.reload.variant_id).to eq(sale_item.product.base_variant.id)
      expect(response).to redirect_to(
        variant_assignment_issues_path(issue_type: "sale_items")
      )
    end
  end

  describe "PATCH /variant_assignment_issues/purchase_item_links/:id" do
    it "repairs the incompatible link through the silent command" do
      original_product = create(:product)
      target_product = create(:product)
      sale_item = create(:sale_item, product: original_product)
      mismatch = create(
        :purchase_item,
        purchase: create(:purchase, product: original_product),
        sale_item:
      )
      exact_inventory = create(
        :purchase_item,
        purchase: create(:purchase, product: target_product)
      )
      sale_item.update_columns(
        product_id: target_product.id,
        variant_id: target_product.base_variant.id
      )

      patch variant_assignment_issues_purchase_item_link_path(mismatch), params: {
        return_to: variant_assignment_issues_path(
          issue_type: "purchase_item_links"
        )
      }

      expect(response).to redirect_to(
        variant_assignment_issues_path(issue_type: "purchase_item_links")
      )
      expect(mismatch.reload.sale_item_id).to be_nil
      expect(exact_inventory.reload.sale_item_id).to eq(sale_item.id)
    end

    it "keeps a concurrently changed unresolved link retryable" do
      purchase_item = create(:purchase_item)
      allow(
        Variant::AssignmentRepair
      ).to receive(:repair_purchase_item_link!).and_raise(
        PurchaseItem::Linking::StaleLinkState
      )

      patch variant_assignment_issues_purchase_item_link_path(purchase_item), params: {
        return_to: variant_assignment_issues_path(
          issue_type: "purchase_item_links"
        )
      }

      expect(response).to redirect_to(
        variant_assignment_issues_path(issue_type: "purchase_item_links")
      )
      expect(flash[:alert]).to eq(
        "This issue changed while it was being repaired. Review it and try again"
      )
    end
  end
end
