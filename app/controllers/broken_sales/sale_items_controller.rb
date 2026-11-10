# frozen_string_literal: true

module BrokenSales
  class SaleItemsController < ApplicationController
    include ReturnPath

    def update
      result = Variant::AssignmentRepair.repair_sale_item_and_requeue_import(
        sale_item_id: params.expect(:id),
        variant_id: repair_params.expect(:variant_id),
        requested_by: Current.user
      )
      redirect_to return_path, notice: success_notice(result)
    rescue Variant::AssignmentRepair::InvalidCandidate => error
      redirect_to return_path, inertia: {errors: {variant_id: error.message}}
    rescue PurchaseItem::Linkable::StaleLinkState
      redirect_to return_path, inertia: {errors: {base: stale_repair_message}}
    end

    private

    def repair_params
      params.expect(sale_item: [:variant_id])
    end

    def success_notice(result)
      return "This line already has a Variant. Nothing was changed." if result.noop?

      [unblocked_notice(result), ("Queued a new pull of the order from the store." if result.queued_pulls.positive?)].compact.join(" ")
    end

    def unblocked_notice(result)
      unblocked = result.unblocked_consequences.filter_map do |consequence|
        case consequence.fetch(:kind)
        when :units_not_reserved then "#{helpers.pluralize(consequence.fetch(:units), "unit")} can now be reserved"
        when :debt_miscounted then "this sale now counts in what we owe for #{result.sale_item.title}"
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
