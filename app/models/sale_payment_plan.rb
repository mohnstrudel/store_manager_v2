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
  # and cost of goods on the same page. Gross revenue is the contract value when
  # the provider states one, so the deal reads as a finished job rather than as
  # whatever has been billed so far.
  def profitability(expense_fraction: ExpenseRate.combined_fraction)
    summaries = related_sales.map { |sale| sale.profitability(expense_fraction:) }
    terms = Sale::Profitability::ADDITIVE_TERMS.index_with { |term|
      total_across(summaries, term)
    }

    terms.merge(
      Sale::Profitability.derived(
        terms,
        gross_revenue: projected_total&.to_d || terms[:expected_revenue],
        expense_fraction:
      )
    )
  end

  # Current parts whose order already exists locally. A plan can name a payment
  # the store has not sent us yet, and such a part has nothing to link to.
  def linked_parts
    parts.select { |part| part.active? && part.sale }
  end

  private

  # One charge that never said what it collected leaves the deal's total
  # unstated too, rather than counting it as nothing.
  def total_across(summaries, term)
    values = summaries.map { |summary| summary.fetch(term) }

    values.sum(0.to_d) unless values.any?(&:nil?)
  end

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

  def positive_net_cash(sale)
    return 0.to_d unless sale

    [sale.received_revenue.to_d - sale.refunded_revenue.to_d, 0.to_d].max
  end
end
