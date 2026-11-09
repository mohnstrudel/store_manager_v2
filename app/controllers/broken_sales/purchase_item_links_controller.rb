# frozen_string_literal: true

module BrokenSales
  class PurchaseItemLinksController < ApplicationController
    include ReturnPath

    def update
      result = Variant::AssignmentRepair.repair_purchase_item_link(
        purchase_item_id: params.expect(:id)
      )
      redirect_to return_path, notice: success_notice(result)
    rescue PurchaseItem::Linkable::StaleLinkState
      redirect_to return_path, alert: stale_repair_message
    end

    private

    def success_notice(result)
      (result == :noop) ? "Variant assignment is already repaired" : "PurchaseItem link was repaired"
    end

    def stale_repair_message
      "This issue changed while it was being repaired. Review it and try again"
    end

    def default_return_path
      broken_sales_path(issue_type: "purchase_item_links")
    end

    def authorize_resource
      authorize :broken_sale, :update?
    end
  end
end
