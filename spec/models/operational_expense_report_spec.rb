# frozen_string_literal: true

require "rails_helper"

RSpec.describe OperationalExpenseReport do
  include ActiveSupport::Testing::TimeHelpers

  it "compares signed actuals with rate assumptions and labels unmatched categories" do
    rate = create(:expense_rate, name: "Payroll", rate_percent: 10)
    create(:sale, status: "completed", expected_revenue: 100, shopify_created_at: Time.zone.local(2026, 6, 10))
    create(:operational_expense, expense_rate: rate, incurred_on: Date.new(2026, 6, 12), amount: 30)
    create(:operational_expense, category: "Rebate", incurred_on: Date.new(2026, 6, 15), amount: -5)

    june = described_class.new(ending_on: Date.new(2026, 6, 30)).rows.find { |row| row[:month] == Date.new(2026, 6, 1) }

    expect(june).to include(
      revenue: BigDecimal("100"),
      assumed_total: BigDecimal("10"),
      actual_total: BigDecimal("25"),
      comparison: {amount: BigDecimal("15"), relation: :over}
    )
    expect(june[:by_rate]).to include({label: "Payroll", assumed: BigDecimal("10"), actual: BigDecimal("30")})
    expect(june[:by_rate]).to include({label: "Unmatched · Rebate", assumed: BigDecimal("0"), actual: BigDecimal("-5")})
  end

  it "buckets actuals linked to a deleted rate as unmatched by category" do
    rate = create(:expense_rate, name: "Legacy ads", rate_percent: 10)
    create(:operational_expense, expense_rate: rate, category: "Ads", incurred_on: Date.new(2026, 6, 12), amount: 20)
    rate.destroy

    june = described_class.new(ending_on: Date.new(2026, 6, 30)).rows.find { |row| row[:month] == Date.new(2026, 6, 1) }

    expect(june[:by_rate]).to include({label: "Unmatched · Ads", assumed: BigDecimal("0"), actual: BigDecimal("20")})
  end

  it "reports actual OpEx below its estimate as under" do
    rate = create(:expense_rate, rate_percent: 20)
    create(:sale, status: "completed", expected_revenue: 100, shopify_created_at: Time.zone.local(2026, 6, 10))
    create(:operational_expense, expense_rate: rate, incurred_on: Date.new(2026, 6, 12), amount: 15)
    create(:operational_expense, category: "Credit", incurred_on: Date.new(2026, 6, 13), amount: -5)

    june = described_class.new(ending_on: Date.new(2026, 6, 30)).rows.find { |row| row[:month] == Date.new(2026, 6, 1) }

    expect(june[:comparison]).to eq({amount: BigDecimal("10"), relation: :under})
  end

  it "reports an exact match without a difference" do
    rate = create(:expense_rate, rate_percent: 20)
    create(:sale, status: "completed", expected_revenue: 100, shopify_created_at: Time.zone.local(2026, 6, 10))
    create(:operational_expense, expense_rate: rate, incurred_on: Date.new(2026, 6, 12), amount: 20)

    june = described_class.new(ending_on: Date.new(2026, 6, 30)).rows.find { |row| row[:month] == Date.new(2026, 6, 1) }

    expect(june[:comparison]).to eq({amount: BigDecimal("0"), relation: :equal})
  end

  it "buckets revenue by woo_created_at when a sale has no shopify_created_at" do
    create(:sale, status: "completed", expected_revenue: 50, shopify_created_at: nil, woo_created_at: Time.zone.local(2026, 6, 10))

    june = described_class.new(ending_on: Date.new(2026, 6, 30)).rows.find { |row| row[:month] == Date.new(2026, 6, 1) }

    expect(june[:revenue]).to eq(BigDecimal("50"))
  end

  it "falls back to created_at when neither shopify_created_at nor woo_created_at is present" do
    travel_to(Time.zone.local(2026, 6, 10)) do
      create(:sale, status: "completed", expected_revenue: 40, shopify_created_at: nil, woo_created_at: nil)
    end

    june = described_class.new(ending_on: Date.new(2026, 6, 30)).rows.find { |row| row[:month] == Date.new(2026, 6, 1) }

    expect(june[:revenue]).to eq(BigDecimal("40"))
  end

  it "returns one row per month across the requested window" do
    rows = described_class.new(months: 3, ending_on: Date.new(2026, 6, 30)).rows

    expect(rows.map { |row| row[:month] }).to eq([Date.new(2026, 4, 1), Date.new(2026, 5, 1), Date.new(2026, 6, 1)])
  end

  it "keeps each month's revenue and actuals separate across the window" do
    rate = create(:expense_rate, rate_percent: 10)
    create(:sale, status: "completed", expected_revenue: 100, shopify_created_at: Time.zone.local(2026, 5, 10))
    create(:sale, status: "completed", expected_revenue: 200, shopify_created_at: Time.zone.local(2026, 6, 10))
    create(:operational_expense, expense_rate: rate, incurred_on: Date.new(2026, 5, 12), amount: 5)
    create(:operational_expense, expense_rate: rate, incurred_on: Date.new(2026, 6, 12), amount: 40)

    rows = described_class.new(months: 2, ending_on: Date.new(2026, 6, 30)).rows
    may = rows.find { |row| row[:month] == Date.new(2026, 5, 1) }
    june = rows.find { |row| row[:month] == Date.new(2026, 6, 1) }

    expect(may).to include(revenue: BigDecimal("100"), assumed_total: BigDecimal("10"), actual_total: BigDecimal("5"))
    expect(june).to include(revenue: BigDecimal("200"), assumed_total: BigDecimal("20"), actual_total: BigDecimal("40"))
  end

  it "rounds the assumed amount to cents" do
    rate = create(:expense_rate, rate_percent: 33)
    create(:sale, status: "completed", expected_revenue: 10, shopify_created_at: Time.zone.local(2026, 6, 10))

    june = described_class.new(ending_on: Date.new(2026, 6, 30)).rows.find { |row| row[:month] == Date.new(2026, 6, 1) }

    expect(june[:assumed_total]).to eq(BigDecimal("3.30"))
  end
end
