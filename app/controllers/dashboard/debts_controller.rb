# frozen_string_literal: true

module Dashboard
  class DebtsController < ApplicationController
    def show
      @unpaid_purchases = Purchase.unpaid.includes(:supplier)
      @debts = if params[:q].present?
        search_query = params.expect(:q).downcase
        Product.with_sale_debts.select do |product|
          product.full_title&.downcase&.include?(search_query) ||
            product.variants.any? do |variant|
              variant.title&.downcase&.include?(search_query)
            end
        end
      else
        Product.with_sale_debts
      end
      @debts = Kaminari.paginate_array(@debts).page(params[:page]).per(25)

      render_inertia "Dashboard/Debts", serializer: Dashboard::DebtsResource,
        locals: {debts: @debts, unpaid_purchases: @unpaid_purchases, query: params[:q].to_s}
    end

    private

    def authorize_resource
      authorize :dashboard, :debts?
    end
  end
end
