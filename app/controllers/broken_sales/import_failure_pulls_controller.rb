# frozen_string_literal: true

module BrokenSales
  class ImportFailurePullsController < ApplicationController
    include ReturnPath

    def create
      failure = Sale::ImportFailure.find(params.expect(:import_failure_id))
      failure.pull_later(requested_by: Current.user)

      redirect_to return_path, notice: "Queued a new pull of order #{failure.store_order_number} from the store."
    end

    private

    def default_return_path
      broken_sales_path(issue_type: "import_failures")
    end

    def authorize_resource
      authorize :broken_sale, :update?
    end
  end
end
