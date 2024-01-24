require "rails_helper"

RSpec.describe SyncPurchasesJob do
  let(:job) { described_class.new }
  let(:product_job) { SyncWooProductsJob.new }
  let(:file) { file_fixture("purchases.json").read }
  let(:parsed_file) { JSON.parse(file, symbolize_names: true) }
  let(:first_parsed_product) {
    product_job.parse_product_name(parsed_file.first[:product])
  }

  describe "#sync_purchases_from_file" do
    before {
      title, franchise_title, shape_title = first_parsed_product
      franchise = create(:franchise, title: franchise_title)
      shape = create(:shape, title: shape_title)
      brand_title = Brand.parse_brand(parsed_file.first[:product])
      brand = if brand_title.present?
        create(:brand, title: brand_title)
      end
      version = create(:version, value: parsed_file.first[:version])
      product = create(
        :product,
        title:,
        franchise:,
        shape:
      )
      create(:product_brand, product:, brand:) if brand.present?
      create(
        :variation,
        product: product,
        version:,
        store_link: nil,
        woo_id: nil
      )

      job.sync_purchases_from_file(file)
    }

    it "imports all purchases from the file" do
      expect(Purchase.all.size).to eq(parsed_file.size)
    end

    it "use existing products" do
      expect(Purchase.first.product).to eq(Product.first)
    end

    it "use existing variations" do
      expect(Purchase.first.variation).to eq(Variation.first)
    end

    it "imports all payments" do
      parsed_payments_size = parsed_file.reduce(0) { |acc, el|
        acc + el.count { |key, _| key.to_s.include?("paymentvalue") }
      }

      expect(Payment.all.size).to eq(parsed_payments_size)
    end
  end
end
