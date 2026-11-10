# frozen_string_literal: true

require "rails_helper"

RSpec.describe BrokenSales::Issues, :aggregate_failures do
  let(:integrity) { Variant::AssignmentIntegrity.new }
  let(:impact) { Variant::AssignmentImpact.new(integrity:) }

  def issues(issue_type, view: nil, reason: nil, scope: nil, product_id: nil)
    described_class.new(integrity:, impact:, issue_type:, view:, reason:, scope:, product_id:)
  end

  def broken_purchase(updated_at: Time.current)
    create(:purchase).tap { |purchase| purchase.update_columns(variant_id: nil, updated_at:) }
  end

  def broken_line(product: create(:product), sale: create(:sale))
    create(:sale_item, sale:, product:).tap { |line| line.update_columns(variant_id: nil) }
  end

  def record_failure(store_order_id, failed_at: Time.current)
    Sale::ImportFailure.record(store_name: "woo", store_order_id:, message: "boom", sentry_event_id: nil, failed_at:)
  end

  def queries_during
    queries = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_name, _started, _finished, _id, payload|
      queries << payload[:sql] unless %w[SCHEMA TRANSACTION].include?(payload[:name])
    end
    yield
    queries
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  describe "#relation" do
    it "lists the broken purchases, latest update first" do
      older = broken_purchase(updated_at: 2.days.ago)
      newer = broken_purchase(updated_at: 1.day.ago)
      create(:purchase)

      expect(issues(:purchases).relation.map(&:id)).to eq([newer.id, older.id])
    end

    it "keeps only the broken purchases of the selected reason" do
      broken_purchase

      expect(issues(:purchases, reason: "missing_variant").relation.count).to eq(1)
      expect(issues(:purchases, reason: "product_mismatch").relation).to be_empty
    end

    it "lists the unresolved import failures, latest failure first" do
      record_failure("older", failed_at: 2.days.ago)
      record_failure("newer", failed_at: 1.day.ago)
      record_failure("resolved", failed_at: Time.current)
      Sale::ImportFailure.resolve(store_name: "woo", store_order_id: "resolved")

      expect(issues(:import_failures).relation.pluck(:store_order_id)).to eq(%w[newer older])
    end

    it "lists the broken order lines of the selected Product" do
      product = create(:product)
      line = broken_line(product:)
      broken_line

      expect(issues(:sale_items, view: "orders", scope: "all", product_id: product.id).relation.map(&:id)).to eq([line.id])
    end

    it "lists the Products with broken order lines in the products view" do
      busy = create(:product)
      2.times { broken_line(product: busy) }
      quiet = create(:product)
      broken_line(product: quiet)

      expect(issues(:sale_items, view: "products", scope: "all").relation.map(&:product_id)).to eq([busy.id, quiet.id])
    end
  end

  describe "#records" do
    it "loads the order lines with the associations the rows show" do
      broken_line
      listed = issues(:sale_items, view: "orders", scope: "all")

      records = listed.records(listed.relation)

      expect(records.sole).to have_attributes(sale: be_a(Sale))
      expect(records.sole.association(:sale)).to be_loaded
      expect(records.sole.association(:product)).to be_loaded
      expect(records.sole.sale.association(:customer)).to be_loaded
    end

    it "loads the Products with their Variants in the products view" do
      broken_line
      listed = issues(:sale_items, view: "products", scope: "all")

      records = listed.records(listed.relation)

      expect(records.sole.association(:product)).to be_loaded
      expect(records.sole.product.association(:variants)).to be_loaded
    end

    it "loads the purchases with their Variants" do
      broken_purchase
      listed = issues(:purchases)

      records = listed.records(listed.relation)

      expect(records.sole.association(:purchase_items)).to be_loaded
      expect(records.sole.association(:product)).to be_loaded
    end

    it "loads the unresolved import failures with their sales" do
      create(:sale, shopify_id: nil, woo_store_id: "88")
      record_failure("88")
      listed = issues(:import_failures)

      records = listed.records(listed.relation)

      expect(records.sole.association(:sale)).to be_loaded
    end
  end

  describe "#lookups" do
    it "names the reason of each listed row" do
      purchase = broken_purchase
      listed = issues(:purchases)

      expect(listed.lookups(listed.records(listed.relation))).to include(reasons: {purchase.id => "missing_variant"})
    end

    it "names no reason in the products view or for import failures" do
      broken_line
      record_failure("88")
      products = issues(:sale_items, view: "products", scope: "all")
      failures = issues(:import_failures)

      expect(products.lookups(products.records(products.relation))).to include(reasons: {})
      expect(failures.lookups(failures.records(failures.relation))).to include(reasons: {})
    end

    describe "siblings by SKU" do
      it "holds only the colliding Variants of the SKUs on the page" do
        products = create_list(:product, 4)
        first = create(:variant, product: products[0], sku: "dup-a")
        second = create(:variant, product: products[1], sku: "dup-a")
        create(:variant, product: products[2], sku: "dup-b")
        create(:variant, product: products[3], sku: "dup-b")
        listed = issues(:sku_collisions)

        siblings = listed.lookups(listed.records(listed.relation.where(id: first.id)))[:siblings_by_sku]

        expect(siblings.keys).to eq(["dup-a"])
        expect(siblings["dup-a"].map(&:id)).to contain_exactly(first.id, second.id)
      end

      it "holds nothing outside the SKU collisions tab" do
        broken_purchase
        listed = issues(:purchases)

        expect(listed.lookups(listed.records(listed.relation))).to include(siblings_by_sku: {})
      end
    end

    describe "import failures by sale" do
      it "holds the unresolved failure of each listed order without loading its sale again" do
        sale = create(:sale, shopify_id: nil, woo_store_id: "88")
        broken_line(sale:)
        broken_line
        record_failure("88")
        listed = issues(:sale_items, view: "orders", scope: "all")
        records = listed.records(listed.relation)
        lookups = nil

        queries = queries_during { lookups = listed.lookups(records) }

        failures = lookups.fetch(:import_failures_by_sale_id)
        expect(failures.keys).to eq([sale.id])
        expect(failures.fetch(sale.id).association(:sale)).to be_loaded
        expect(failures.fetch(sale.id).sale).to be(records.find { |record| record.sale_id == sale.id }.sale)
        expect(queries.grep(/FROM "sales"/)).to be_empty
      end

      it "leaves out resolved failures" do
        sale = create(:sale, shopify_id: nil, woo_store_id: "88")
        broken_line(sale:)
        record_failure("88")
        Sale::ImportFailure.resolve(store_name: "woo", store_order_id: "88")
        listed = issues(:sale_items, view: "orders", scope: "all")

        expect(listed.lookups(listed.records(listed.relation))).to include(import_failures_by_sale_id: {})
      end

      it "holds nothing in the products view" do
        broken_line(sale: create(:sale, shopify_id: nil, woo_store_id: "88"))
        record_failure("88")
        listed = issues(:sale_items, view: "products", scope: "all")

        expect(listed.lookups(listed.records(listed.relation))).to include(import_failures_by_sale_id: {})
      end
    end

    describe "replacements by identity" do
      it "groups the unlinked purchase items by the identity of each listed link's SaleItem" do
        original_product = create(:product)
        target_product = create(:product)
        mismatch = create(
          :purchase_item,
          purchase: create(:purchase, product: original_product),
          sale_item: create(:sale_item, product: original_product, qty: 2)
        )
        exact_inventory = create(:purchase_item, purchase: create(:purchase, product: target_product))
        mismatch.sale_item.update_columns(product_id: target_product.id, variant_id: target_product.base_variant.id)
        listed = issues(:purchase_item_links)

        lookups = listed.lookups(listed.records(listed.relation))

        expect(lookups.fetch(:replacements_by_identity)).to eq(
          [target_product.id, target_product.base_variant.id] => [exact_inventory.id]
        )
      end

      it "holds nothing outside the purchase item links tab" do
        broken_purchase
        listed = issues(:purchases)

        expect(listed.lookups(listed.records(listed.relation))).to include(replacements_by_identity: {})
      end
    end
  end
end
