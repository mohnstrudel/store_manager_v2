# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sale::Woo::Pull, :aggregate_failures do
  let(:client) { instance_double(Woo::Api::Client) }
  let(:woo_orders) { JSON.parse(file_fixture("api_orders.json").read, symbolize_names: true) }
  let(:first_order) { woo_orders.first }
  let(:last_order) { woo_orders.last }
  let(:unmapped_order) { first_order.deep_dup.merge(id: 999, status: "new-status") }

  before do
    allow(Woo::Api::Client).to receive(:new).and_return(client)
    allow(client).to receive(:fetch_orders).and_return(woo_orders)
    create(:exchange_rate, date: Date.new(2000, 1, 1), currency: "USD", rate: BigDecimal("1.1250"))
    create(:product, woo_store_id: "11")
    create(:product, woo_store_id: "22")
  end

  describe ".run" do
    it "imports every fetched order" do
      described_class.run

      expect(Sale.find_by_woo_id(111)).to be_present
      expect(Sale.find_by_woo_id(222)).to be_present
    end

    it "fetches the default number of orders" do
      described_class.run

      expect(client).to have_received(:fetch_orders).with(2700, nil)
    end

    it "passes a custom limit and page count to the client" do
      described_class.run(limit: 100, pages: 5)

      expect(client).to have_received(:fetch_orders).with(100, 5)
    end

    it "fetches a single order when an id is given" do
      allow(client).to receive(:fetch_order).with("111").and_return(first_order)

      described_class.run(id: "111")

      expect(client).not_to have_received(:fetch_orders)
      expect(Sale.find_by_woo_id(111)).to be_present
      expect(Sale.find_by_woo_id(222)).to be_nil
    end

    it "raises NotFound and imports nothing when Woo has no order for the id" do
      allow(client).to receive(:fetch_order).with("404").and_raise(Woo::Api::Client::NotFound.new("gone"))

      expect { expect { described_class.run(id: "404") }.to raise_error(Woo::Api::Client::NotFound) }.not_to change(Sale, :count)
    end

    it "raises and imports nothing when fetching the orders fails" do
      allow(client).to receive(:fetch_orders).and_raise(Woo::Api::Client::Unavailable.new("down"))

      expect { expect { described_class.run }.to raise_error(Woo::Api::Client::Unavailable) }.not_to change(Sale, :count)
    end

    it "fails only the order whose product cannot be fetched and imports the rest" do
      unreachable_order = first_order.deep_dup
      unreachable_order[:line_items].first[:product_id] = 99
      allow(client).to receive(:fetch_orders).and_return([unreachable_order, last_order])
      allow(Product::Woo::Importer).to receive(:fetch_and_import).with(99).and_raise(Woo::Api::Client::Unavailable.new("down"))

      expect { described_class.run }.to raise_error(described_class::Failed) { |error|
        expect(error.failures).to match([have_attributes(woo_id: unreachable_order[:id], message: "Woo::Api::Client::Unavailable: down")])
      }

      expect(Sale.find_by_woo_id(unreachable_order[:id])).to be_nil
      expect(Sale.find_by_woo_id(last_order[:id])).to be_present
    end

    it "does not report an order with a skipped line as a failed pull" do
      skipped_order = first_order.deep_dup
      skipped_order[:line_items].first[:product_id] = 99
      allow(client).to receive(:fetch_orders).and_return([skipped_order])
      allow(Product::Woo::Importer).to receive(:fetch_and_import).and_return(nil)

      expect { described_class.run }.not_to raise_error

      expect(Sale.find_by_woo_id(skipped_order[:id])).to be_present
      expect(Sale::ImportFailure.find_by!(store_name: "woo", store_order_id: skipped_order[:id].to_s).resolved_at).to be_nil
    end

    it "keeps importing the other orders when the parser rejects one" do
      allow(client).to receive(:fetch_orders).and_return([first_order, unmapped_order, last_order])

      freeze_time do
        expect { described_class.run }.to raise_error(described_class::Failed) { |error|
          expect(error.failures).to eq(
            [described_class::Failure.new(woo_id: 999, message: 'ArgumentError: Unmapped Woo status: "new-status"', failed_at: Time.current)]
          )
        }
      end

      expect(Sale.find_by_woo_id(111)).to be_present
      expect(Sale.find_by_woo_id(222)).to be_present
      expect(Sale.find_by_woo_id(999)).to be_nil
    end

    context "when an existing line has no Variant and its order carries no Variant options" do
      let(:product) { create(:product, woo_store_id: "33") }
      let(:sale) { create(:sale, woo_store_id: "333", status: "processing") }
      let!(:sale_item) { create_sale_item_without_variant }
      let(:broken_order) do
        first_order.deep_dup.merge(
          id: 333, status: "completed",
          line_items: [first_order[:line_items].first.merge(id: 9000, product_id: 33, meta_data: [])]
        )
      end

      def create_sale_item_without_variant
        variant = create(:variant, :with_version, product:)
        create(:sale_item, product:, variant:, sale:, woo_store_id: "9000").tap do |item|
          item.update_column(:variant_id, nil) # rubocop:disable Rails/SkipsModelValidations
        end
      end

      before { allow(client).to receive(:fetch_orders).and_return([broken_order, *woo_orders]) }

      it "imports that order and keeps the line without a Variant", :aggregate_failures do
        expect { described_class.run }.not_to raise_error

        expect(sale.reload.status).to eq("completed")
        expect(sale_item.reload.variant_id).to be_nil
        expect(Sale.find_by_woo_id(111)).to be_present
      end
    end

    it "logs the backtrace of a failed order" do
      allow(client).to receive(:fetch_orders).and_return([unmapped_order])
      allow(Rails.logger).to receive(:error)

      expect { described_class.run }.to raise_error(described_class::Failed)

      expect(Rails.logger).to have_received(:error).with(/Woo order 999 failed to import: .*parser\.rb/m)
    end

    [
      ActiveRecord::ConnectionNotEstablished,
      ActiveRecord::ConnectionFailed,
      ActiveRecord::QueryCanceled,
      ActiveRecord::Deadlocked,
      ActiveRecord::SerializationFailure,
      ActiveRecord::LockWaitTimeout
    ].each do |infrastructure_error|
      it "re-raises #{infrastructure_error} instead of blaming the order" do
        allow(Sale::Woo::Parser).to receive(:parse).and_raise(infrastructure_error)

        expect { described_class.run }.to raise_error(infrastructure_error)
      end
    end
  end

  describe Sale::Woo::Pull::Failed do
    it "describes at most the first ten failures and keeps them all" do
      failures = Array.new(12) { |index| Sale::Woo::Pull::Failure.new(woo_id: index, message: "boom #{index}", failed_at: Time.current) }

      error = described_class.new(failures)

      expect(error.failures).to eq(failures)
      expect(error.message).to start_with("12 Woo order(s) failed to import: 0: boom 0; ")
      expect(error.message).to include("9: boom 9")
      expect(error.message).not_to include("10: boom 10")
    end
  end
end
