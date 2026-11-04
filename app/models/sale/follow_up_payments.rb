# frozen_string_literal: true

module Sale::FollowUpPayments
  extend ActiveSupport::Concern

  included do
    has_many :origin_payment_plans,
      class_name: "SalePaymentPlan",
      foreign_key: :origin_sale_id,
      dependent: :nullify,
      inverse_of: :origin_sale
    has_many :sale_payment_parts, dependent: :nullify, inverse_of: :sale

    scope :follow_up_payments, -> { where(id: follow_up_payment_sale_ids) }
    scope :without_follow_up_payments, -> { where.not(id: follow_up_payment_sale_ids) }
  end

  class_methods do
    def follow_up_payment_sale_ids
      SalePaymentPart.active
        .joins(:sale_payment_plan)
        .where.not(sale_id: nil)
        .where("sale_payment_plans.origin_sale_id IS DISTINCT FROM sale_payment_parts.sale_id")
        .select(:sale_id)
    end
  end

  def follow_up_payment?
    payment_plans.any? { |plan| plan.origin_sale_id != id && plan.part_number_for(self).present? }
  end

  def payment_plans
    (origin_payment_plans.to_a + sale_payment_parts.map(&:sale_payment_plan))
      .uniq(&:id)
      .sort_by { |plan| [plan.created_at, plan.id] }
  end

  def linked_to_payment_plan?
    SalePaymentPlan.exists?(origin_sale_id: id) ||
      SalePaymentPart.exists?(sale_id: id, active: true)
  end

  def projected_item_price
    return if sale_items.size != 1
    return if shipping_total.blank?

    plans = payment_plans
    return unless plans.one?

    plan = plans.first
    return unless plan.origin_sale_id == id && plan.projected_total

    price = plan.projected_total - shipping_total.to_d
    price if price >= 0
  end

  def reconcile_installment_attribution(origin_item)
    installment_payment_items.each { |item| item.apply_installment_origin(origin_item) }
  end

  def installment_payment_items
    scope = sale_items.joins(:product)
    scope.where(products: {non_catalog: true}).or(scope.where.not(sale_items: {origin_sale_item_id: nil}))
  end

  def reconcile_installment_sale_items_later
    Seal::ReconcileInstallmentSaleItemsJob.perform_later(sale_id: id)
  end
end
