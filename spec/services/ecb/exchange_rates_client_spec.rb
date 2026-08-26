# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ecb::ExchangeRatesClient do
  let(:client) { described_class.new }

  describe "#fetch_all", :vcr do
    context "when the ECB history feed responds successfully" do
      it "requests exactly the ECB reference-rate history feed" do
        VCR.use_cassette("ecb/history") do
          expect { client.fetch_all }.not_to raise_error
        end
      end

      it "parses every date/currency/rate row from the nested Cube structure" do
        rows = VCR.use_cassette("ecb/history") { client.fetch_all }

        expect(rows).to contain_exactly(
          {date: Date.new(2026, 8, 21), currency: "USD", rate: BigDecimal("1.1250")},
          {date: Date.new(2026, 8, 21), currency: "CHF", rate: BigDecimal("0.9375")},
          {date: Date.new(2026, 8, 20), currency: "USD", rate: BigDecimal("1.1200")},
          {date: Date.new(2026, 8, 20), currency: "CHF", rate: BigDecimal("0.9350")}
        )
      end
    end

    context "when the ECB history feed returns an unsuccessful response" do
      it "raises FetchError" do
        VCR.use_cassette("ecb/unsuccessful_response") do
          expect { client.fetch_all }.to raise_error(described_class::FetchError, /HTTP 503/)
        end
      end
    end

    context "when the ECB history feed returns malformed XML" do
      it "raises FetchError" do
        VCR.use_cassette("ecb/malformed_response") do
          expect { client.fetch_all }.to raise_error(described_class::FetchError)
        end
      end
    end

    context "when the ECB history feed returns well-formed XML with no rate data" do
      it "raises FetchError" do
        VCR.use_cassette("ecb/empty_response") do
          expect { client.fetch_all }.to raise_error(described_class::FetchError, /no data/)
        end
      end
    end
  end
end
