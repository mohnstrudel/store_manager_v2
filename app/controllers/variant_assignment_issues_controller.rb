# frozen_string_literal: true

class VariantAssignmentIssuesController < ApplicationController
  PER_PAGE = 25

  def index
    integrity = Variant::AssignmentIntegrity.new
    issue_type = selected_issue_type
    reason = selected_reason(integrity, issue_type)
    issues = integrity
      .relation_for(issue_type, reason:)
      .order(updated_at: :desc, id: :desc)
      .page(params[:page])
      .per(PER_PAGE)

    render inertia: "VariantAssignmentIssues/Index", props: {
      issue_type: issue_type.to_s,
      filter: reason.to_s,
      counts: integrity.counts,
      filters: integrity.reasons_for(issue_type).map { |value|
        {value:, label: reason_label(value)}
      },
      issues: issue_props(integrity, issue_type, issues),
      pagination: helpers.pagination_props(issues)
    }
  end

  private

  def authorize_resource
    authorize :variant_assignment_issue, :index?
  end

  def selected_issue_type
    requested = params[:issue_type].presence&.to_sym
    Variant::AssignmentIntegrity::ISSUE_TYPES.include?(requested) ? requested : :purchases
  end

  def selected_reason(integrity, issue_type)
    requested = params[:reason].to_s
    integrity.reasons_for(issue_type).include?(requested) ? requested : nil
  end

  def issue_props(integrity, issue_type, issues)
    case issue_type
    when :purchases
      issues.includes(:variant, :purchase_items, product: {variants: %i[color size version]}).map { |purchase|
        assignment_props(integrity, :purchases, purchase).merge(
          reference: purchase.order_reference.presence || "Purchase ##{purchase.id}",
          inventory_units: purchase.purchase_items.size,
          linked_units: purchase.purchase_items.count { |purchase_item| purchase_item.sale_item_id.present? },
          record_path: purchase_path(purchase)
        )
      }
    when :sale_items
      issues.includes(:variant, :purchase_items, :sale, product: {variants: %i[color size version]}).map { |sale_item|
        assignment_props(integrity, :sale_items, sale_item).merge(
          reference: "Sale ##{sale_item.sale_id}, item ##{sale_item.id}",
          ordered_units: sale_item.qty.to_i,
          linked_units: sale_item.purchase_items.size,
          record_path: sale_path(sale_item.sale)
        )
      }
    when :purchase_item_links
      issues.includes(
        purchase: [:product, {variant: %i[color size version]}],
        sale_item: [:product, :sale, {variant: %i[color size version]}]
      ).map { |purchase_item| link_issue_props(integrity, purchase_item) }
    end
  end

  def assignment_props(integrity, issue_type, record)
    product = record.product || record.variant&.product

    {
      kind: (issue_type == :purchases) ? "purchase" : "sale_item",
      id: record.id,
      reason: integrity.reason_for(issue_type, record.id),
      product_id: record.product_id,
      product_title: product&.full_title || "Missing Product",
      variant_id: record.variant_id,
      current_variant_label: record.variant&.assignment_label || "Missing Variant",
      current_variant_product_id: record.variant&.product_id,
      candidates: repair_candidates(product)
    }
  end

  def repair_candidates(product)
    return [] unless product

    product
      .variant_repair_candidates
      .includes(:color, :size, :version)
      .order(:id)
      .map { |variant|
        {
          value: variant.id,
          label: variant.assignment_label,
          base_model: variant.base_model?
        }
      }
  end

  def link_issue_props(integrity, purchase_item)
    sale_item = purchase_item.sale_item
    replacements = PurchaseItem.where(
      sale_item_id: nil,
      product_id: sale_item.product_id,
      variant_id: sale_item.variant_id
    ).order(:id)

    {
      kind: "purchase_item_link",
      id: purchase_item.id,
      reason: integrity.reason_for(:purchase_item_links, purchase_item.id),
      purchase_id: purchase_item.purchase_id,
      purchase_path: purchase_path(purchase_item.purchase),
      sale_item_id: sale_item.id,
      sale_path: sale_path(sale_item.sale),
      purchase_product_title: purchase_item.purchase.product&.full_title || "Missing Product",
      purchase_variant_label: purchase_item.purchase.variant&.assignment_label || "Missing Variant",
      sale_product_title: sale_item.product&.full_title || "Missing Product",
      sale_variant_label: sale_item.variant&.assignment_label || "Missing Variant",
      exact_replacements_available: replacements.count,
      exact_replacement_ids: replacements.ids,
      remaining_capacity_after_unlink: [
        sale_item.qty.to_i - sale_item.purchase_items_count.to_i + 1,
        0
      ].max
    }
  end

  def reason_label(reason)
    {
      "missing_product" => "Missing Product",
      "missing_variant" => "Missing Variant",
      "product_mismatch" => "Product / Variant mismatch",
      "purchase_identity" => "Purchase identity mismatch",
      "sale_item_identity" => "SaleItem identity mismatch"
    }.fetch(reason)
  end
end
