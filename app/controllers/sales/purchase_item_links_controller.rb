# frozen_string_literal: true

module Sales
  class PurchaseItemLinksController < ApplicationController
    include SaleScoped

    def create
      @sale.link_purchase_items
      redirect_to @sale, success: "Sold products were interlinked with purchased products"
    end

    private

    def authorize_resource
      authorize :sale, :link_purchase_items?
    end
  end
end
