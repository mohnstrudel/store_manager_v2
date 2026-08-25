# frozen_string_literal: true

# Ecb::ExchangeRatesClient
#
# Fetches the European Central Bank's full published reference-rate history
# (every currency, every business day, since the euro's introduction) in one
# request so historical sale dates never need a second ECB round trip.
#
# Usage:
#   client = Ecb::ExchangeRatesClient.new
#   client.fetch_all # => [{date:, currency:, rate:}, ...]
module Ecb
  class ExchangeRatesClient
    class FetchError < StandardError; end

    HISTORY_URL = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-hist.xml"

    def fetch_all
      response = HTTParty.get(HISTORY_URL)

      raise FetchError, "ECB rates request failed: HTTP #{response.code}" unless response.success?

      parse(response.body)
    rescue HTTParty::Error, Nokogiri::XML::SyntaxError => e
      raise FetchError, "ECB rates request failed: #{e.class}: #{e.message}"
    end

    private

    def parse(xml_body)
      document = Nokogiri::XML(xml_body) { |config| config.strict }
      document.remove_namespaces!

      rows = document.xpath("//Cube[@time]").flat_map do |day_cube|
        date = Date.parse(day_cube["time"])

        day_cube.xpath("Cube[@currency]").map do |rate_cube|
          {date:, currency: rate_cube["currency"], rate: BigDecimal(rate_cube["rate"])}
        end
      end

      raise FetchError, "ECB rates response contained no data" if rows.empty?

      rows
    end
  end
end
