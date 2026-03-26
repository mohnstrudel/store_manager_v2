# frozen_string_literal: true

module Sales
  class PurchaseItemLinksController < ApplicationController
    include SaleScoped

    def create
      @sale.link_purchase_items!
      redirect_to @sale, notice: "Success! Sold products were interlinked with purchased products"
    end

    private

    def authorize_resourse
      authorize :sale, :link_purchase_items?
    end
  end
end
