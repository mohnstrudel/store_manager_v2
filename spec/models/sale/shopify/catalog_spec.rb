# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Shopify::Catalog, :aggregate_failures do
  let(:product_store_id) { "gid://shopify/Product/1" }
  let(:variant_store_id) { "gid://shopify/ProductVariant/1" }
  let(:product) { create(:product, :synced, shopify_id: product_store_id) }
  let(:variant) { create(:variant, :synced, :with_version, product:, shopify_id: variant_store_id) }
  let(:order_updated_at) { Time.zone.local(2026, 11, 1, 12) }

  def catalog(*lines)
    described_class.new(lines.map { |line| {product_store_id: nil, variant_store_id: nil}.merge(line) })
  end

  def store_id_selects(&)
    selects = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
      selects << payload[:sql] if payload[:sql].start_with?("SELECT") && payload[:sql].include?('"store_infos"."store_id"')
    end
    yield
    selects
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  describe "#product and #variant" do
    it "return the local records of the Shopify ids the lines reference" do
      product
      variant

      subject = catalog({product_store_id:, variant_store_id:})

      expect(subject.product(product_store_id)).to eq(product)
      expect(subject.variant(variant_store_id)).to eq(variant)
    end

    it "return nothing for a blank or unknown id" do
      subject = catalog({product_store_id:, variant_store_id:})

      expect(subject.product(nil)).to be_nil
      expect(subject.variant("")).to be_nil
      expect(subject.product(product_store_id)).to be_nil
      expect(subject.variant(variant_store_id)).to be_nil
    end

    it "keep the Product and the Variant of the same Shopify id apart" do
      shared_id = "gid://shopify/Shared/1"
      shared_product = create(:product, :synced, shopify_id: shared_id)
      shared_variant = create(:variant, :synced, :with_version, product: shared_product, shopify_id: shared_id)

      subject = catalog({product_store_id: shared_id, variant_store_id: shared_id})

      expect(subject.product(shared_id)).to eq(shared_product)
      expect(subject.variant(shared_id)).to eq(shared_variant)
    end

    it "ignore a record linked to another store" do
      product.store_infos.shopify.delete_all
      product.upsert_woo_info(store_id: product_store_id)

      expect(catalog({product_store_id:}).product(product_store_id)).to be_nil
    end

    it "read every referenced record in one query per record type" do
      products = Array.new(3) { |index| create(:product, :synced, shopify_id: "gid://shopify/Product/many-#{index}") }
      variants = products.each_with_index.map { |item, index| create(:variant, :synced, :with_version, product: item, shopify_id: "gid://shopify/ProductVariant/many-#{index}") }
      subject = catalog(*products.zip(variants).map { |item, option| {product_store_id: item.shopify_store_id, variant_store_id: option.shopify_store_id} })

      selects = store_id_selects do
        products.each { |item| subject.product(item.shopify_store_id) }
        variants.each { |option| subject.variant(option.shopify_store_id) }
      end

      expect(selects.size).to eq(2)
    end

    it "find a record created after the first lookup" do
      subject = catalog({product_store_id:})
      expect(subject.product(product_store_id)).to be_nil

      product

      expect(subject.product(product_store_id)).to eq(product)
    end
  end

  describe "#missing_product_store_ids" do
    def missing(subject, order_updated_at: self.order_updated_at)
      subject.missing_product_store_ids(order_updated_at:)
    end

    it "names the products that are not cached" do
      expect(missing(catalog({product_store_id:, variant_store_id:}))).to eq([product_store_id])
    end

    it "names each missing product once" do
      subject = catalog({product_store_id:, variant_store_id:}, {product_store_id:, variant_store_id: "gid://shopify/ProductVariant/2"})

      expect(missing(subject)).to eq([product_store_id])
    end

    it "names nothing when the product and the variant are cached" do
      variant

      expect(missing(catalog({product_store_id:, variant_store_id:}))).to be_empty
    end

    it "names nothing for a cached product on a line without a variant" do
      product

      expect(missing(catalog({product_store_id:}))).to be_empty
    end

    it "names nothing for a line without a Shopify product" do
      expect(missing(catalog({variant_store_id:}, {}))).to be_empty
    end

    context "when the product is cached without its variant" do
      before { product }

      it "names the product when it has no pull time" do
        expect(missing(catalog({product_store_id:, variant_store_id:}))).to eq([product_store_id])
      end

      it "names the product when it was pulled before the order's last update" do
        product.shopify_info.update!(pull_time: order_updated_at - 1.hour)

        expect(missing(catalog({product_store_id:, variant_store_id:}))).to eq([product_store_id])
      end

      it "names nothing when it was pulled after the order's last update" do
        product.shopify_info.update!(pull_time: order_updated_at + 1.hour)

        expect(missing(catalog({product_store_id:, variant_store_id:}))).to be_empty
      end

      it "names the product when the order's last update is unknown" do
        product.shopify_info.update!(pull_time: order_updated_at + 1.hour)

        expect(missing(catalog({product_store_id:, variant_store_id:}), order_updated_at: nil)).to eq([product_store_id])
      end
    end
  end

  describe "#reload" do
    it "forgets what it read so records changed since are read again" do
      subject = catalog({product_store_id:})
      expect(subject.product(product_store_id)).to be_nil
      product
      subject.reload

      expect(subject.product(product_store_id)).to eq(product)
      expect(subject.reload).to be(subject)
    end
  end
end
