require "rails_helper"

RSpec.describe SyncWooOrdersJob do
  let(:job) {
    described_class.new
  }
  let(:woo_orders) {
    JSON.parse(file_fixture("api_orders.json").read, symbolize_names: true)
  }
  let(:parsed_woo_orders) {
    JSON.parse(file_fixture("parsed_orders.json").read, symbolize_names: true)
  }

  describe "#parse_all" do
    context "when we receive an array of orders from Woo API" do
      it "gives us parsed result" do
        parsed = job.parse_all(woo_orders)
        expect(parsed).to eq(parsed_woo_orders)
      end
    end
  end

  describe "#get_customer_id" do
    context "when we receive a valid woo_id" do
      it "returns existing customer" do
        parsed_customer = parsed_woo_orders.first[:customer]
        existing_customer = create(
          :customer,
          email: "#{SecureRandom.hex(5)}@mail.com",
          woo_id: parsed_customer[:woo_id]
        )
        parsed_customer_id = job.get_customer_id(parsed_customer)

        expect(parsed_customer_id).to eq(existing_customer.id)
      end
    end

    context "when we receive invalid woo_id" do
      let(:parsed_customer) { parsed_woo_orders.last[:customer] }

      let(:existing_customer) {
        create(
          :customer,
          email: parsed_customer[:email],
          woo_id: nil
        )
      }

      it "returns existing customer if woo_id == 0" do
        existing_customer_id = existing_customer.id
        parsed_customer_id = job.get_customer_id(
          parsed_customer.merge(woo_id: 0)
        )

        expect(parsed_customer_id).to eq(existing_customer_id)
      end

      it "returns existing customer if woo_id == '0'" do
        existing_customer_id = existing_customer.id
        parsed_customer_id = job.get_customer_id(
          parsed_customer.merge(woo_id: "0")
        )

        expect(parsed_customer_id).to eq(existing_customer_id)
      end

      it "returns existing customer if woo_id == ''" do
        existing_customer_id = existing_customer.id
        parsed_customer_id = job.get_customer_id(
          parsed_customer.merge(woo_id: "")
        )

        expect(parsed_customer_id).to eq(existing_customer_id)
      end
    end
  end

  describe "#create_sales" do
    let(:denpasar) { "Denpasar" }
    let(:weird_link) { "hey ho, let's go" }

    context "when we parsed orders from Woo API" do
      before do
        create(
          :sale,
          woo_id: parsed_woo_orders.first[:sale][:woo_id],
          city: denpasar
        )
        create(
          :edition,
          woo_id: parsed_woo_orders.first[:products].first[:edition][:woo_id],
          store_link: weird_link
        )
        parsed_woo_orders.pluck(:products).flatten.each do |p|
          create(:product, woo_id: p[:product_woo_id])
        end
        job.create_sales(parsed_woo_orders)
      end

      it "saves each product to the DB" do
        expect(Sale.all.size).to eq(parsed_woo_orders.size)
      end

      it "creates product sales with editions" do
        with_edition = ProductSale.where.not(edition_id: nil)
        parsed_editions_count = parsed_woo_orders.pluck(:products).flatten.count { |product| product[:edition].present? }
        expect(with_edition.size).to eq(parsed_editions_count)
      end

      it "reuses existing sales" do
        existing_sale = Sale.find_by(woo_id: parsed_woo_orders.first[:sale][:woo_id])
        expect(existing_sale.city).not_to eq(denpasar)
      end

      it "reuses existing editions" do
        existing_edition = Edition.find_by(woo_id: parsed_woo_orders.first[:products].first[:edition][:woo_id])
        expect(existing_edition.store_link).to eq(weird_link)
      end
    end
  end
end
