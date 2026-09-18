# frozen_string_literal: true

require "rails_helper"

# == Schema Information
#
# Table name: exchange_rates
#
#  id         :bigint           not null, primary key
#  currency   :string           not null
#  date       :date             not null
#  fetched_at :datetime         not null
#  rate       :decimal(15, 4)   not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
RSpec.describe ExchangeRate do
  describe "validations" do
    it "rejects a duplicate date/currency rate" do
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD")
      duplicate = build(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:date]).to be_present
    end

    it "allows the same date for different currencies" do
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD")
      other_currency = build(:exchange_rate, date: Date.new(2026, 8, 21), currency: "CHF")

      expect(other_currency).to be_valid
    end

    it "rejects a non-positive rate at the database layer" do
      expect {
        create(:exchange_rate, rate: BigDecimal(0))
      }.to raise_error(ActiveRecord::StatementInvalid, /exchange_rates_positive_rate/)

      expect {
        create(:exchange_rate, rate: BigDecimal("-1.5"))
      }.to raise_error(ActiveRecord::StatementInvalid, /exchange_rates_positive_rate/)
    end
  end

  describe ".usd_amount" do
    before do
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD", rate: BigDecimal("1.1250"))
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "CHF", rate: BigDecimal("0.9375"))
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "GBP", rate: BigDecimal("0.8700"))
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "CAD", rate: BigDecimal("1.5000"))
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "AUD", rate: BigDecimal("1.6500"))
    end

    it "converts EUR to USD directly with decimal arithmetic" do
      expect(described_class.usd_amount(BigDecimal("100.00"), currency: "EUR", date: Date.new(2026, 8, 21)))
        .to eq(BigDecimal("112.50"))
    end

    it "converts CHF to USD through the EUR cross-rate" do
      expect(described_class.usd_amount(BigDecimal("100.00"), currency: "CHF", date: Date.new(2026, 8, 21)))
        .to eq(BigDecimal("120.00"))
    end

    it "converts GBP, CAD, and AUD through the same generic cross-rate path", :aggregate_failures do
      expect(described_class.usd_amount(BigDecimal("87.00"), currency: "GBP", date: Date.new(2026, 8, 21)))
        .to eq(BigDecimal("112.50"))
      expect(described_class.usd_amount(BigDecimal("150.00"), currency: "CAD", date: Date.new(2026, 8, 21)))
        .to eq(BigDecimal("112.50"))
      expect(described_class.usd_amount(BigDecimal("165.00"), currency: "AUD", date: Date.new(2026, 8, 21)))
        .to eq(BigDecimal("112.50"))
    end

    it "passes USD through unchanged without an external lookup" do
      expect(HTTParty).not_to receive(:get)

      expect(described_class.usd_amount(BigDecimal("42.99"), currency: "USD", date: Date.new(2026, 8, 21)))
        .to eq(BigDecimal("42.99"))
    end

    it "uses the latest earlier published rate on a Saturday, Sunday, or ECB holiday" do
      sunday = Date.new(2026, 8, 23)

      expect(described_class.usd_amount(BigDecimal("100.00"), currency: "CHF", date: sunday))
        .to eq(BigDecimal("120.00"))
    end

    it "rounds to the cent at a half-cent boundary" do
      create(:exchange_rate, date: Date.new(2026, 8, 22), currency: "USD", rate: BigDecimal("1.1250"))

      expect(described_class.usd_amount(BigDecimal("1.00"), currency: "EUR", date: Date.new(2026, 8, 22)))
        .to eq(BigDecimal("1.13"))
    end
  end

  describe ".usd_amount caching", :vcr do
    it "fetches once from ECB and reuses cached rates without another HTTP request" do
      VCR.use_cassette("ecb/history") do
        described_class.usd_amount(BigDecimal("100.00"), currency: "CHF", date: Date.new(2026, 8, 21))
      end

      expect(described_class.usd_amount(BigDecimal("50.00"), currency: "CHF", date: Date.new(2026, 8, 21)))
        .to eq(BigDecimal("60.00"))
    end

    it "persists the fetched rates for reuse" do
      VCR.use_cassette("ecb/history") do
        described_class.usd_amount(BigDecimal("100.00"), currency: "CHF", date: Date.new(2026, 8, 21))
      end

      expect(described_class.where(currency: "USD", date: Date.new(2026, 8, 21)).pick(:rate))
        .to eq(BigDecimal("1.1250"))
    end
  end

  describe ".rate_on when a currency's ECB history starts after the requested date" do
    before do
      create(:exchange_rate, date: Date.new(2027, 1, 15), currency: "XYZ", rate: BigDecimal("1.10"))
      create(:exchange_rate, date: Date.new(2027, 1, 18), currency: "XYZ", rate: BigDecimal("1.12"))
      create(:exchange_rate, date: Date.new(2027, 1, 19), currency: "XYZ", rate: BigDecimal("1.08"))
      create(:exchange_rate, date: Date.new(2027, 1, 20), currency: "XYZ", rate: BigDecimal("1.14"))
      create(:exchange_rate, date: Date.new(2027, 1, 21), currency: "XYZ", rate: BigDecimal("1.09"))
      create(:exchange_rate, date: Date.new(2027, 1, 22), currency: "XYZ", rate: BigDecimal("1.11"))
    end

    it "resolves to the median of rates within three months of the currency's earliest cached date" do
      expect(HTTParty).not_to receive(:get)

      expect(described_class.rate_on(currency: "XYZ", date: Date.new(2026, 12, 1)))
        .to eq(BigDecimal("1.105"))
    end

    it "still uses an exact or earlier-dated rate directly when one exists" do
      create(:exchange_rate, date: Date.new(2026, 11, 1), currency: "XYZ", rate: BigDecimal("1.20"))

      expect(described_class.rate_on(currency: "XYZ", date: Date.new(2026, 12, 1)))
        .to eq(BigDecimal("1.20"))
    end

    it "raises for a currency with zero cached rows at any date" do
      expect {
        described_class.rate_on(currency: "ZZZ", date: Date.new(2026, 12, 1))
      }.to raise_error(ArgumentError, /No ECB reference rate cached for ZZZ/)
    end
  end

  describe ".usd_amount when the ECB response is unsuccessful or malformed", :vcr do
    it "persists no rate rows when the HTTP response is unsuccessful" do
      VCR.use_cassette("ecb/unsuccessful_response") do
        expect {
          described_class.usd_amount(BigDecimal("100.00"), currency: "CHF", date: Date.new(2026, 8, 21))
        }.to raise_error(Ecb::ExchangeRatesClient::FetchError)
      end

      expect(described_class.count).to eq(0)
    end

    it "persists no rate rows when the response body is malformed XML" do
      VCR.use_cassette("ecb/malformed_response") do
        expect {
          described_class.usd_amount(BigDecimal("100.00"), currency: "CHF", date: Date.new(2026, 8, 21))
        }.to raise_error(Ecb::ExchangeRatesClient::FetchError)
      end

      expect(described_class.count).to eq(0)
    end
  end

  describe ".eur_to_usd_conversion" do
    it "returns the order date, effective ECB date, positive rate, and a cent-rounded USD amount" do
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD", rate: BigDecimal("1.1250"))

      conversion = described_class.eur_to_usd_conversion(date: Date.new(2026, 8, 21))

      expect(conversion.order_date).to eq(Date.new(2026, 8, 21))
      expect(conversion.effective_date).to eq(Date.new(2026, 8, 21))
      expect(conversion.rate).to eq(BigDecimal("1.1250"))
      expect(conversion.usd_amount(BigDecimal("100.00"))).to eq(BigDecimal("112.50"))
    end

    it "uses the latest earlier published rate on a Saturday, Sunday, or ECB holiday" do
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD", rate: BigDecimal("1.1250"))
      sunday = Date.new(2026, 8, 23)

      conversion = described_class.eur_to_usd_conversion(date: sunday)

      expect(conversion.order_date).to eq(sunday)
      expect(conversion.effective_date).to eq(Date.new(2026, 8, 21))
      expect(conversion.rate).to eq(BigDecimal("1.1250"))
    end

    it "does not fall back to the median rate that a legacy caller would still receive" do
      create(:exchange_rate, date: Date.new(2027, 1, 18), currency: "USD", rate: BigDecimal("1.12"))
      create(:exchange_rate, date: Date.new(2027, 1, 20), currency: "USD", rate: BigDecimal("1.14"))

      expect {
        described_class.eur_to_usd_conversion(date: Date.new(2026, 12, 1))
      }.to raise_error(ArgumentError, /No ECB EUR-to-USD rate cached/)

      expect(described_class.rate_on(currency: "USD", date: Date.new(2026, 12, 1))).to eq(BigDecimal("1.13"))
    end

    it "raises when no USD rate is cached on or before the requested date" do
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD", rate: BigDecimal("1.1250"), fetched_at: 1.hour.ago)

      expect {
        described_class.eur_to_usd_conversion(date: Date.new(2020, 1, 1))
      }.to raise_error(ArgumentError, /No ECB EUR-to-USD rate cached/)
    end
  end

  describe ".eur_to_usd_conversion caching", :vcr do
    it "makes one full-history request when the cache is empty" do
      conversion = VCR.use_cassette("ecb/history") do
        described_class.eur_to_usd_conversion(date: Date.new(2026, 8, 21))
      end

      expect(conversion.rate).to eq(BigDecimal("1.1250"))
      expect(described_class.count).to eq(4)
    end

    it "makes no request when the cache was refreshed less than 24 hours ago" do
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD", rate: BigDecimal("1.1250"), fetched_at: 1.hour.ago)

      conversion = described_class.eur_to_usd_conversion(date: Date.new(2026, 8, 21))

      expect(conversion.rate).to eq(BigDecimal("1.1250"))
    end

    it "makes one recent-feed request when the cache is older than 24 hours" do
      create(:exchange_rate, date: Date.new(2026, 8, 20), currency: "USD", rate: BigDecimal("1.1200"), fetched_at: 25.hours.ago)

      conversion = VCR.use_cassette("ecb/recent") do
        described_class.eur_to_usd_conversion(date: Date.new(2026, 8, 21))
      end

      expect(conversion.rate).to eq(BigDecimal("1.1250"))
    end

    it "records freshness on a successful refresh even when the recent feed adds no new publication date" do
      create(:exchange_rate, date: Date.new(2026, 8, 21), currency: "USD", rate: BigDecimal("1.1250"), fetched_at: 25.hours.ago)
      create(:exchange_rate, date: Date.new(2026, 8, 20), currency: "USD", rate: BigDecimal("1.1200"), fetched_at: 25.hours.ago)

      VCR.use_cassette("ecb/recent") do
        described_class.eur_to_usd_conversion(date: Date.new(2026, 8, 21))
      end

      expect {
        described_class.eur_to_usd_conversion(date: Date.new(2026, 8, 21))
      }.not_to raise_error
    end

    it "does not alter historical rates outside the refreshed window" do
      create(:exchange_rate, date: Date.new(2020, 1, 1), currency: "USD", rate: BigDecimal("1.5000"), fetched_at: 25.hours.ago)
      create(:exchange_rate, date: Date.new(2026, 8, 20), currency: "USD", rate: BigDecimal("1.1200"), fetched_at: 25.hours.ago)

      VCR.use_cassette("ecb/recent") do
        described_class.eur_to_usd_conversion(date: Date.new(2026, 8, 21))
      end

      expect(described_class.find_by(date: Date.new(2020, 1, 1), currency: "USD").rate).to eq(BigDecimal("1.5000"))
    end

    it "reuses stored rows for many conversions after one refresh with no further requests" do
      create(:exchange_rate, date: Date.new(2026, 8, 20), currency: "USD", rate: BigDecimal("1.1200"), fetched_at: 25.hours.ago)

      VCR.use_cassette("ecb/recent") do
        described_class.eur_to_usd_conversion(date: Date.new(2026, 8, 21))
      end

      results = Array.new(3) { described_class.eur_to_usd_conversion(date: Date.new(2026, 8, 21)) }

      expect(results).to all(have_attributes(rate: BigDecimal("1.1250")))
    end

    it "raises and persists nothing when the required ECB fetch fails" do
      VCR.use_cassette("ecb/unsuccessful_response") do
        expect {
          described_class.eur_to_usd_conversion(date: Date.new(2026, 8, 21))
        }.to raise_error(Ecb::ExchangeRatesClient::FetchError)
      end

      expect(described_class.count).to eq(0)
    end
  end
end
