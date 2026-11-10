# frozen_string_literal: true

module BrokenSales
  class ClosedOrderRepairsController < ApplicationController
    include ReturnPath

    def create
      result = Variant::AssignmentRepair.repair_closed_sale_items(
        product_id: Product.friendly.find(params.expect(:product_id)).id,
        variant_id: repair_params.expect(:variant_id),
        requested_by: Current.user
      )
      redirect_to return_path, notice: result_notice(result)
    rescue Variant::AssignmentRepair::InvalidCandidate => error
      redirect_to return_path, inertia: {errors: {variant_id: error.message}}
    end

    private

    def repair_params
      params.expect(closed_order_repair: [:variant_id])
    end

    def result_notice(result)
      [
        repaired_notice(result.repaired),
        ("Skipped #{helpers.pluralize(result.skipped, "line")}." if result.skipped.positive?),
        ("Could not assign #{helpers.pluralize(result.failed, "line")}. Try again." if result.failed.positive?),
        ("Queued a new pull of #{helpers.pluralize(result.queued_pulls, "order")} from the store." if result.queued_pulls.positive?)
      ].compact.join(" ")
    end

    def repaired_notice(repaired)
      return "Assigned the Variant to 0 lines." if repaired.zero?

      "Fixed: history now records the Variant for #{helpers.pluralize(repaired, "closed line")}."
    end

    def default_return_path
      broken_sales_path(issue_type: "sale_items", view: "products")
    end

    def authorize_resource
      authorize :broken_sale, :update?
    end
  end
end
