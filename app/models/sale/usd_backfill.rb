# frozen_string_literal: true

class Sale::UsdBackfill
  SALE_MONEY_FIELDS = %i[
    discount_total shipping_total total expected_revenue
    received_revenue outstanding_revenue refunded_revenue net_payment
  ].freeze
  ITEM_MONEY_FIELDS = %i[price expected_revenue].freeze

  Result = Struct.new(:converted_sale_ids, :unresolved_sale_ids, :failed_sale_ids)

  def self.call(shopify_currency:)
    new(shopify_currency:).call
  end

  def initialize(shopify_currency:)
    @shopify_currency = shopify_currency
  end

  def call
    converted = []
    unresolved = []
    failed = []

    Sale.where(settlement_status: nil).find_each do |sale|
      case convert_sale(sale)
      when :converted then converted << sale.id
      when :unresolved then unresolved << sale.id
      when :failed then failed << sale.id
      end
    end

    Result.new(converted, unresolved, failed)
  end

  private

  attr_reader :shopify_currency

  def convert_sale(sale)
    if sale.shopify_id.present?
      convert_shopify!(sale)
    elsif sale.woo_id.present?
      convert_woo!(sale)
    else
      sale.update!(settlement_status: "unknown")
      :converted
    end
  end

  def convert_shopify!(sale)
    date = sale.shopify_created_at&.to_date
    return :unresolved if date.nil?

    convert!(sale, currency: shopify_currency, date:) do |money|
      Sale.settlement_status_from_shopify(financial_status: sale.financial_status, outstanding_revenue: money[:outstanding_revenue])
    end
  end

  def convert_woo!(sale)
    date = sale.woo_created_at&.to_date
    return :unresolved if date.nil?

    convert!(sale, currency: "EUR", date:) do |_money|
      Sale.settlement_status_from_woo(status: sale.status, date_paid: woo_date_paid_marker(sale))
    end
  end

  # received_revenue positivity reconstructs Woo's date_paid presence for non-partial statuses.
  def woo_date_paid_marker(sale)
    Time.current if sale.received_revenue.to_d.positive?
  end

  def convert!(sale, currency:, date:)
    Sale.transaction do
      money = SALE_MONEY_FIELDS.index_with { |field| convert(sale[field], currency:, date:) }
      sale.update!(money.merge(settlement_status: yield(money)))

      sale.sale_items.each do |item|
        item.update!(ITEM_MONEY_FIELDS.index_with { |field| convert(item[field], currency:, date:) })
      end

      sale.allocate_revenue_to_items!
      convert_payment_plans!(sale, date:)
    end

    :converted
  rescue
    :failed
  end

  # Each row's own recorded currency decides whether it still needs converting.
  def convert_payment_plans!(sale, date:)
    SalePaymentPlan.where(origin_sale_id: sale.id).find_each do |plan|
      if convertible_currency?(plan.currency)
        plan.update!(projected_total: convert(plan.projected_total, currency: plan.currency, date:))
      end

      plan.parts.each do |part|
        next unless convertible_currency?(part.currency)

        part.update!(amount: convert(part.amount, currency: part.currency, date:))
      end
    end
  end

  def convertible_currency?(currency)
    currency.present? && currency != "USD"
  end

  def convert(amount, currency:, date:)
    return nil if amount.blank?

    ExchangeRate.usd_amount(amount, currency:, date:)
  end
end
