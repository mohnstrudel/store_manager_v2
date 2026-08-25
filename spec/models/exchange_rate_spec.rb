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
#  rate       :decimal(10, 4)   not null
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

  describe ".usd_amount caching" do
    let(:history_body) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
          <Cube>
            <Cube time="2026-08-21">
              <Cube currency="USD" rate="1.1250"/>
              <Cube currency="CHF" rate="0.9375"/>
            </Cube>
          </Cube>
        </gesmes:Envelope>
      XML
    end
    let(:response) { instance_double(HTTParty::Response, success?: true, body: history_body) }

    before do
      allow(HTTParty).to receive(:get).and_return(response)
    end

    it "fetches once from ECB and reuses cached rates without another HTTP request" do
      described_class.usd_amount(BigDecimal("100.00"), currency: "CHF", date: Date.new(2026, 8, 21))
      described_class.usd_amount(BigDecimal("50.00"), currency: "CHF", date: Date.new(2026, 8, 21))

      expect(HTTParty).to have_received(:get).once
    end

    it "persists the fetched rates for reuse" do
      described_class.usd_amount(BigDecimal("100.00"), currency: "CHF", date: Date.new(2026, 8, 21))

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

      # Sorted XYZ rates: 1.08, 1.09, 1.10, 1.11, 1.12, 1.14 — hand-computed median
      # of the middle two (1.10, 1.11) is 1.105, independent of the fallback code.
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

  describe ".usd_amount when the ECB response is unsuccessful or malformed" do
    it "persists no rate rows when the HTTP response is unsuccessful" do
      allow(HTTParty).to receive(:get).and_return(instance_double(HTTParty::Response, success?: false, code: 503, body: ""))

      expect {
        described_class.usd_amount(BigDecimal("100.00"), currency: "CHF", date: Date.new(2026, 8, 21))
      }.to raise_error(Ecb::ExchangeRatesClient::FetchError)

      expect(described_class.count).to eq(0)
    end

    it "persists no rate rows when the response body is malformed XML" do
      allow(HTTParty).to receive(:get).and_return(instance_double(HTTParty::Response, success?: true, body: "not xml <<<"))

      expect {
        described_class.usd_amount(BigDecimal("100.00"), currency: "CHF", date: Date.new(2026, 8, 21))
      }.to raise_error(Ecb::ExchangeRatesClient::FetchError)

      expect(described_class.count).to eq(0)
    end
  end
end
