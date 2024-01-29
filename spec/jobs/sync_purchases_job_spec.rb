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

  describe "#validate_keys" do
    it "returns no errors and a false boolean indicating there are no validation errors" do
      parsed_purchase = {
        amount: 100,
        supplier: "Supplier Name",
        itemprice: 50,
        orderreference: "Order Reference",
        product: "Product Name",
        purchasedate: "2022-01-01"
      }
      errors = []

      result, has_errors = job.validate_keys(parsed_purchase, errors)

      expect(result).to eq(errors)
      expect(has_errors).to be(false)
    end

    it "returns errors and a true boolean indicating there are validation errors" do
      parsed_purchase = {
        amount: nil,
        supplier: "Supplier Name",
        itemprice: 50,
        orderreference: "Order Reference",
        product: "Product Name",
        purchasedate: "2022-01-01"
      }
      errors = []

      result, has_errors = job.validate_keys(parsed_purchase, errors)

      expect(result).to eq(errors)
      expect(has_errors).to be(true)
    end
  end

  describe "sanitize_product_name" do
    it "removes 'Resin Statue' from the string" do
      expect(job.sanitize_product_name("Resin Statue | Example")).to eq("| Example")
    end

    it "removes 'Deposit' from the string" do
      expect(job.sanitize_product_name("Deposit | Example")).to eq("| Example")
    end

    it "removes '（Copyright）' from the string" do
      expect(job.sanitize_product_name("（Copyright） | Example")).to eq("| Example")
    end

    it "strips the string" do
      expect(job.sanitize_product_name("  Example  ")).to eq("Example")
    end
  end

  describe "#parse_versions" do
    before {
      @expected_color = create(:color, value: "Black")
      @expected_size = create(:size, value: "1:1")
      @expected_version = create(:version, value: "Deluxe")
    }
    let(:parsed_color_version) { "Black" }
    let(:parsed_size_version) { "1:1" }
    let(:parsed_version_version) { "Deluxe" }

    it "returns color, size, and version" do
      color, _, _ = job.parse_versions(parsed_color_version)
      _, size, _ = job.parse_versions(parsed_size_version)
      _, _, version = job.parse_versions(parsed_version_version)

      expect(color).to eq(@expected_color)
      expect(size).to eq(@expected_size)
      expect(version).to eq(@expected_version)
    end

    it "handles unknown color" do
      color, _, _ = job.parse_versions("Pink")

      expect(color.value).to eq("Pink")
    end
  end
end
