# frozen_string_literal: true

module Dashboard
  class DebtsController < ApplicationController
    include DashboardDebtReporting

    def show
      @unpaid_purchases = Purchase.unpaid.includes(:supplier)
      @debts = if params[:q].present?
        search_query = params[:q].downcase
        sale_debts.select do |product|
          product.full_title&.downcase&.include?(search_query) ||
            product.variants.any? do |variant|
              variant.title&.downcase&.include?(search_query)
            end
        end
      else
        sale_debts
      end
      @debts = Kaminari.paginate_array(@debts).page(params[:page]).per(25)

      render "dashboard/debts"
    end

    private

    def authorize_resourse
      authorize :dashboard, :debts?
    end
  end
end
