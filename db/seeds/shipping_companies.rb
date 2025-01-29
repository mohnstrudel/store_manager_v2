# Seed data for shipping companies
shipping_companies = [
  {
    name: "DHL",
    tracking_url: "https://www.dhl.com/global-en/home/tracking/tracking-express.html?submit=1&tracking-id="
  },
  {
    name: "FedEx",
    tracking_url: "https://www.fedex.com/tracking?tracknumbers="
  },
  {
    name: "UPS",
    tracking_url: "https://www.ups.com/track?loc=en_US&tracknum="
  },
  {
    name: "USPS",
    tracking_url: "https://tools.usps.com/go/TrackConfirmAction_input?strOrigTrackNum="
  },
  {
    name: "Royal Mail",
    tracking_url: "https://www.royalmail.com/track-your-item"
  }
]

shipping_companies.each do |company_attrs|
  ShippingCompany.find_or_create_by!(name: company_attrs[:name]) do |company|
    company.tracking_url = company_attrs[:tracking_url]
  end
end
