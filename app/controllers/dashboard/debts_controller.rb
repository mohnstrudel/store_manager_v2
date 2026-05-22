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

      render inertia: "Dashboard/Debts", props: {
        debts: @debts.map { |debt| debt_props(debt) },
        pagination: pagination_props(@debts),
        search: {q: params[:q].to_s},
        unpaid_purchases: @unpaid_purchases.map { |purchase| unpaid_purchase_props(purchase) }
      }
    end

    private

    def authorize_resourse
      authorize :dashboard, :debts?
    end

    def debt_props(product)
      variant = product.sale_variant_id.present?

      {
        id: product.id,
        path: product_path(product.slug),
        row_id: product.sale_variant_id || product.id,
        title: product.full_title.to_s,
        variant_name: variant ? product.variant_name.to_s : "",
        sold_amount: product.sold_amount.to_i,
        purchased_amount: variant ? product.purchased_variants_amount.to_i : product.purchased_amount.to_i,
        debt: variant ? product.variants_debt.to_i : product.debt.to_i
      }
    end

    def unpaid_purchase_props(purchase)
      {
        id: purchase.id,
        path: purchase_path(purchase),
        purchased_ago: helpers.time_ago_in_words(purchase.created_at),
        supplier_title: purchase.supplier.title.to_s,
        item_price: helpers.format_money(purchase.item_price).to_s,
        amount: purchase.amount.to_i
      }
    end
  end
end
