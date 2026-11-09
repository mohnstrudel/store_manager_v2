# frozen_string_literal: true

module BrokenSales
  class SaleItemsController < ApplicationController
    include ReturnPath

    def update
      blocked = blocked_consequences
      result = Variant::AssignmentRepair.repair_sale_item(
        sale_item_id: params.expect(:id),
        variant_id: repair_params.expect(:variant_id)
      )
      queued_pulls = (result == :repaired) ? pull_failed_order_later : 0
      redirect_to return_path, notice: success_notice(result, blocked, queued_pulls)
    rescue Variant::AssignmentRepair::InvalidCandidate => error
      redirect_to return_path, inertia: {errors: {variant_id: error.message}}
    rescue PurchaseItem::Linkable::StaleLinkState
      redirect_to return_path, inertia: {errors: {base: stale_repair_message}}
    end

    private

    def blocked_consequences
      sale_item = SaleItem.preload(:sale, product: :variants, variant: {product: :variants}).find(params.expect(:id))
      integrity = Variant::AssignmentIntegrity.new
      Variant::AssignmentImpact.new(integrity:).consequences(sale_item, reason: integrity.reason_for(:sale_items, sale_item))
    end

    def repair_params
      params.expect(sale_item: [:variant_id])
    end

    def pull_failed_order_later
      Sale::ImportFailure.pull_unresolved_later(sale_ids: SaleItem.where(id: params.expect(:id)).select(:sale_id))
    end

    def success_notice(result, blocked, queued_pulls)
      return "Variant assignment is already repaired" if result == :noop

      [unblocked_notice(blocked), ("Queued a new pull of the order from the store." if queued_pulls.positive?)].compact.join(" ")
    end

    def unblocked_notice(blocked)
      unblocked = blocked.filter_map do |consequence|
        case consequence.fetch(:kind)
        when :units_not_reserved then "#{helpers.pluralize(consequence.fetch(:units), "unit")} can now be reserved"
        when :debt_miscounted then "this sale now counts in what we owe for #{SaleItem.find(params.expect(:id)).title}"
        end
      end

      "Fixed: #{unblocked.presence&.join(", and ") || "history now records the Variant for this line"}."
    end

    def stale_repair_message
      "This issue changed while it was being repaired. Review it and try again"
    end

    def default_return_path
      broken_sales_path(issue_type: "sale_items")
    end

    def authorize_resource
      authorize :broken_sale, :update?
    end
  end
end
