# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ecb::ExchangeRatesClient do
  let(:client) { described_class.new }

  describe "#fetch_all" do
    context "when the ECB history feed responds successfully" do
      let(:history_body) do
        <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref">
            <Cube>
              <Cube time="2026-08-21">
                <Cube currency="USD" rate="1.1250"/>
                <Cube currency="CHF" rate="0.9375"/>
              </Cube>
              <Cube time="2026-08-20">
                <Cube currency="USD" rate="1.1200"/>
                <Cube currency="CHF" rate="0.9350"/>
              </Cube>
            </Cube>
          </gesmes:Envelope>
        XML
      end

      before do
        allow(HTTParty).to receive(:get).and_return(instance_double(HTTParty::Response, success?: true, body: history_body))
      end

      it "requests the ECB reference-rate history feed" do
        client.fetch_all

        expect(HTTParty).to have_received(:get).with(described_class::HISTORY_URL)
      end

      it "parses every date/currency/rate row from the nested Cube structure" do
        rows = client.fetch_all

        expect(rows).to contain_exactly(
          {date: Date.new(2026, 8, 21), currency: "USD", rate: BigDecimal("1.1250")},
          {date: Date.new(2026, 8, 21), currency: "CHF", rate: BigDecimal("0.9375")},
          {date: Date.new(2026, 8, 20), currency: "USD", rate: BigDecimal("1.1200")},
          {date: Date.new(2026, 8, 20), currency: "CHF", rate: BigDecimal("0.9350")}
        )
      end
    end

    context "when the ECB history feed returns an unsuccessful response" do
      before do
        allow(HTTParty).to receive(:get).and_return(instance_double(HTTParty::Response, success?: false, code: 503, body: ""))
      end

      it "raises FetchError" do
        expect { client.fetch_all }.to raise_error(described_class::FetchError, /HTTP 503/)
      end
    end

    context "when the ECB history feed returns malformed XML" do
      before do
        allow(HTTParty).to receive(:get).and_return(instance_double(HTTParty::Response, success?: true, body: "not xml <<<"))
      end

      it "raises FetchError" do
        expect { client.fetch_all }.to raise_error(described_class::FetchError)
      end
    end

    context "when the ECB history feed returns well-formed XML with no rate data" do
      before do
        allow(HTTParty).to receive(:get).and_return(
          instance_double(
            HTTParty::Response,
            success?: true,
            body: '<?xml version="1.0"?><gesmes:Envelope xmlns:gesmes="http://www.gesmes.org/xml/2002-08-01" xmlns="http://www.ecb.int/vocabulary/2002-08-01/eurofxref"><Cube></Cube></gesmes:Envelope>'
          )
        )
      end

      it "raises FetchError" do
        expect { client.fetch_all }.to raise_error(described_class::FetchError, /no data/)
      end
    end
  end
end
