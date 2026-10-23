# frozen_string_literal: true

module Sale::FollowUpPayments
  extend ActiveSupport::Concern

  included do
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
    payment_plans_for_display.any? { |plan| plan.origin_sale_id != id && plan.part_number_for(self).present? }
  end
end
