# frozen_string_literal: true

module VariantAssignmentIssues
  class PurchaseItemLinksController < ApplicationController
    def update
      result = Variant::AssignmentRepair.repair_purchase_item_link!(
        purchase_item_id: params.expect(:id)
      )
      redirect_to return_path, notice: success_notice(result)
    rescue PurchaseItem::Linking::StaleLinkState
      redirect_to return_path, alert: stale_repair_message
    end

    private

    def authorize_resource
      authorize :variant_assignment_issue, :update?
    end

    def return_path
      params[:return_to].presence ||
        variant_assignment_issues_path(issue_type: "purchase_item_links")
    end

    def success_notice(result)
      (result == :noop) ? "Variant assignment is already repaired" : "PurchaseItem link was repaired"
    end

    def stale_repair_message
      "This issue changed while it was being repaired. Review it and try again"
    end
  end
end
