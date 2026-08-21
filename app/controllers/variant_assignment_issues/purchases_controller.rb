# frozen_string_literal: true

module VariantAssignmentIssues
  class PurchasesController < ApplicationController
    def update
      result = Variant::AssignmentRepair.repair_purchase!(
        purchase_id: Purchase.friendly.find(params.expect(:id)).id,
        variant_id: repair_params.expect(:variant_id)
      )
      redirect_to return_path, notice: success_notice(result)
    rescue Variant::AssignmentRepair::InvalidCandidate => error
      redirect_to return_path, inertia: {errors: {variant_id: error.message}}
    rescue PurchaseItem::Linking::StaleLinkState
      redirect_to return_path, inertia: {errors: {base: stale_repair_message}}
    end

    private

    def authorize_resource
      authorize :variant_assignment_issue, :update?
    end

    def repair_params
      params.expect(purchase: [:variant_id])
    end

    def return_path
      params[:return_to].presence || variant_assignment_issues_path
    end

    def success_notice(result)
      (result == :noop) ? "Variant assignment is already repaired" : "Purchase Variant was repaired"
    end

    def stale_repair_message
      "This issue changed while it was being repaired. Review it and try again"
    end
  end
end
