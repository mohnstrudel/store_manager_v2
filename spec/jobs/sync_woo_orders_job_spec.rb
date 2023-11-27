require "rails_helper"

RSpec.describe SyncWooOrdersJob do
  let(:job) {
    described_class.new
  }
  let(:woo_orders) { JSON.parse(file_fixture("api_orders.json").read, symbolize_names: true) }
  let(:parsed_woo_orders) { JSON.parse(file_fixture("parsed_orders.json").read, symbolize_names: true) }

  describe "#parse_orders" do
    context "when we receive an array of orders from Woo API" do
      it "gives us parsed result" do
        parsed = job.parse_orders(woo_orders)
        expect(parsed).to eq(parsed_woo_orders)
      end
    end
  end

  describe "#create_sales" do
    context "when we parsed orders from Woo API" do
      before do
        parsed_woo_orders.pluck(:products).flatten.each do |p|
          create(:product, woo_id: p[:product_woo_id])
        end
        job.create_sales(parsed_woo_orders)
      end

      it "saves each product to the DB" do
        expect(Sale.all.size).to eq(parsed_woo_orders.size)
      end

      it "creates product sales with variations" do
        with_variation = ProductSale.where.not(variation_id: nil)
        parsed_variations_count = parsed_woo_orders.pluck(:products).flatten.count { |product| product[:variation].present? }
        expect(with_variation.size).to eq(parsed_variations_count)
      end
    end
  end
end
