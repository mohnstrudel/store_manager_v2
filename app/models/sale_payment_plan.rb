# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_payment_plans
#
#  id                       :bigint           not null, primary key
#  currency                 :string
#  deposit_percent          :decimal(5, 2)
#  expected_parts           :integer          not null
#  kind                     :string           not null
#  next_due_at              :datetime
#  projected_total          :decimal(12, 2)
#  provider                 :string           not null
#  status                   :string
#  synced_at                :datetime         not null
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  external_id              :string           not null
#  external_origin_order_id :string
#  origin_sale_id           :bigint
#
class SalePaymentPlan < ApplicationRecord
  PROVIDERS = %w[seal shopify].freeze
  KINDS = %w[deposit installments payment_terms].freeze
  # Additive terms of a sale's profitability summary. Profit is derived from the
  # totals afterwards rather than summed, so the plan states one equation.
  PROFITABILITY_COMPONENTS = %i[
    expected_revenue
    received_revenue
    outstanding_revenue
    refunded_revenue
    purchase_cost
    direct_expenses
    merchandise_cost
    business_expenses
  ].freeze

  belongs_to :origin_sale, class_name: "Sale", optional: true, inverse_of: :origin_payment_plans
  has_many :parts,
    -> { order(:sequence) },
    class_name: "SalePaymentPart",
    dependent: :destroy,
    inverse_of: :sale_payment_plan

  validates :provider, inclusion: {in: PROVIDERS}
  validates :kind, inclusion: {in: KINDS}
  validates :external_id, presence: true
  validates :expected_parts, numericality: {only_integer: true, greater_than: 0}
  validates :synced_at, presence: true
  validates :deposit_percent,
    numericality: {greater_than: 0, less_than_or_equal_to: 100},
    allow_nil: true
  validates_db_uniqueness_of :external_id, scope: :provider

  def self.reconcile!(attributes:, parts:)
    plan_attributes = attributes.to_h.symbolize_keys
    provider = plan_attributes.fetch(:provider)
    external_id = plan_attributes.fetch(:external_id).to_s

    transaction do
      plan = lock.find_or_initialize_by(provider:, external_id:)
      plan.assign_attributes(
        plan_attributes.except(:provider, :external_id).merge(
          external_origin_order_id: Sale::Shopify::OrderId.normalize(
            plan_attributes[:external_origin_order_id]
          )
        )
      )
      plan.origin_sale = Sale::Shopify::OrderId.find_sale(plan.external_origin_order_id)
      plan.save!
      plan.reconcile_parts!(parts)
      plan
    end
  end

  def self.reconcile_sale!(sale)
    normalized_order_id = Sale::Shopify::OrderId.normalize(sale.shopify_store_id)
    return if normalized_order_id.blank?

    transaction do
      where(external_origin_order_id: normalized_order_id).update_all(
        origin_sale_id: sale.id,
        updated_at: Time.current
      )
      SalePaymentPart.where(external_order_id: normalized_order_id).update_all(
        sale_id: sale.id,
        updated_at: Time.current
      )
    end
  end

  def self.projected_deposit_total(deposit_merchandise_amount:, deposit_percent:, shipping_amount:)
    percent = deposit_percent.to_d
    return if percent <= 0

    (deposit_merchandise_amount.to_d / (percent / 100)) + shipping_amount.to_d
  end

  def reconcile_parts!(part_snapshots)
    parts.update_all(active: false)

    Array(part_snapshots).each do |snapshot|
      reconcile_part!(snapshot.to_h.symbolize_keys)
    end

    parts.where(active: false, sale_id: nil).delete_all
    parts.reset
  end

  def collected_parts
    return shopify_collected_parts if provider == "shopify"

    parts.active.includes(:sale).count { |part| settled_with_positive_cash?(part.sale) }
  end

  def projected_remainder
    return if projected_total.nil?

    collected = related_sales.sum { |sale| positive_net_cash(sale) }
    [projected_total - collected, 0.to_d].max
  end

  def part_number_for(sale)
    parts.active.find { |part| part.sale_id == sale.id }&.sequence
  end

  # Economics of the whole deal. The purchase links sit on the originating order
  # while the money arrives across every charge, so only the plan can put revenue
  # and cost of goods on the same page.
  def profitability(expense_fraction: ExpenseRate.combined_fraction)
    summaries = related_sales.map { |sale| sale.profitability(expense_fraction:) }
    totals = PROFITABILITY_COMPONENTS.index_with { |component|
      summaries.sum(0.to_d) { |summary| summary.fetch(component) }
    }

    totals.merge(
      realized_profit: totals[:received_revenue] - totals[:purchase_cost] - totals[:business_expenses],
      expected_final_profit: totals[:expected_revenue] - totals[:purchase_cost] - totals[:business_expenses],
      **projected_profitability(totals[:purchase_cost], expense_fraction)
    )
  end

  # Current parts whose order already exists locally. A plan can name a payment
  # the store has not sent us yet, and such a part has nothing to link to.
  def linked_parts
    parts.select { |part| part.active? && part.sale }
  end

  private

  def reconcile_part!(snapshot)
    provider_part_id = snapshot[:provider_part_id].presence&.to_s
    sequence = snapshot.fetch(:sequence)
    part = parts.find_by(provider_part_id:) if provider_part_id
    part ||= parts.find_by(sequence:)
    part ||= parts.build

    external_order_id = Sale::Shopify::OrderId.normalize(snapshot[:external_order_id])
    part.assign_attributes(
      snapshot.except(:external_order_id).merge(
        provider_part_id:,
        external_order_id:,
        active: true
      )
    )
    part.sale = Sale::Shopify::OrderId.find_sale(external_order_id) if external_order_id
    part.save!
  end

  def shopify_collected_parts
    return 0 unless positive_net_cash(origin_sale).positive?

    parts.active.count { |part| part.provider_completed_at.present? }
  end

  def settled_with_positive_cash?(sale)
    sale && sale.outstanding_revenue.to_d <= 0 && positive_net_cash(sale).positive?
  end

  def related_sales
    ([origin_sale] + parts.active.includes(:sale).map(&:sale)).compact.uniq
  end

  # The full-deal profit next to the booked one: purchase_cost is the plan's
  # already-summed cost of goods and needs no projecting, but revenue and OpEx
  # both scale to the contract value so a deposit isn't measured against 100%
  # of the cost on 30% of the revenue. Absent a contract value there is
  # nothing to project, so all three keys stay explicit nil together rather
  # than a mix of present and absent keys.
  def projected_profitability(purchase_cost, expense_fraction)
    if projected_total.nil?
      return {projected_revenue: nil, projected_business_expenses: nil, projected_final_profit: nil}
    end

    business_expenses = (projected_total.to_d * expense_fraction).round(2)

    {
      projected_revenue: projected_total,
      projected_business_expenses: business_expenses,
      projected_final_profit: projected_total - purchase_cost - business_expenses
    }
  end

  def positive_net_cash(sale)
    return 0.to_d unless sale

    [sale.received_revenue.to_d - sale.refunded_revenue.to_d, 0.to_d].max
  end
end
