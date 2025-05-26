require "rails_helper"

RSpec.describe Shopify::SaleCreator do
  let(:parsed_orders) { instance_eval(file_fixture("shopify_parsed_orders.rb").read) }
  let(:valid_parsed_order) { parsed_orders.first }
  let(:creator) { described_class.new(parsed_item: valid_parsed_order) }
  let(:products_size) { valid_parsed_order[:product_sales].count { |ps| ps.key?(:product) } }

  describe "#update_or_create" do
    context "with invalid input" do
      it "raises error when parsed_order is not a Hash" do
        expect { described_class.new(parsed_item: nil).update_or_create! }.to raise_error(ArgumentError, "Order data must be a Hash")
      end

      it "raises error when parsed_order is blank" do
        expect { described_class.new(parsed_item: {}).update_or_create! }.to raise_error(ArgumentError, "Order data is required")
      end

      it "raises error when customer data is missing" do
        invalid_order = valid_parsed_order.dup
        invalid_order[:customer] = nil
        expect { described_class.new(parsed_item: invalid_order).update_or_create! }.to raise_error(ArgumentError, "Customer data is required")
      end

      it "raises error when sale data is missing" do
        invalid_order = valid_parsed_order.dup
        invalid_order[:sale] = nil
        expect { described_class.new(parsed_item: invalid_order).update_or_create! }.to raise_error(ArgumentError, "Sale data is required")
      end

      it "raises error when product_sales is missing" do
        invalid_order = valid_parsed_order.dup
        invalid_order[:product_sales] = nil
        expect { described_class.new(parsed_item: invalid_order).update_or_create! }.to raise_error(ArgumentError, "Product sales data is required")
      end
    end

    context "when creating a new sale" do
      it "creates all required records" do
        expect { creator.update_or_create! }.to change(Sale, :count).by(1)
          .and change(Customer, :count).by(1)
          .and change(ProductSale, :count).by(1)
          .and change(Product, :count).by(products_size)
          .and change(Edition, :count).by(2)
      end

      it "associates customer with sale" do
        creator.update_or_create!
        expect(Sale.last.customer).to eq(Customer.last)
      end
    end

    context "when sale already exists" do
      before do
        creator.update_or_create!
      end

      it "updates existing records instead of creating new ones" do
        expect { creator.update_or_create! }.not_to change(Sale, :count)
        expect { creator.update_or_create! }.not_to change(Customer, :count)
        expect { creator.update_or_create! }.not_to change(ProductSale, :count)
      end
    end

    context "when edition already exists" do
      let(:parsed_order) { valid_parsed_order }
      let!(:existing_edition) { create(:edition, shopify_id: parsed_order[:product_sales].first[:shopify_edition_id]) }

      it "uses existing edition" do
        expect { creator.update_or_create! }.not_to change(Edition, :count)
        expect(ProductSale.last.edition).to eq(existing_edition)
      end
    end

    context "when product sale is corrupted" do
      let(:parsed_order_corrupted) do
        order = valid_parsed_order.deep_dup
        order[:product_sales].first[:shopify_edition_id] = nil
        order[:product_sales].first[:shopify_product_id] = nil
        order[:product_sales].first[:edition_title] = nil
        order
      end
      let(:creator_corrupted) { described_class.new(parsed_item: parsed_order_corrupted) }

      it "does not create a new edition when edition_title is missing" do
        expect { creator_corrupted.update_or_create! }.not_to change(Edition, :count)
      end

      it "still creates the product sale without a edition" do
        expect { creator_corrupted.update_or_create! }.to change(ProductSale, :count).by(1)
        expect(ProductSale.last.edition).to be_nil
      end
    end

    context "when there are errors" do
      before do
        allow_any_instance_of(Sale).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Sale.new))
      end

      it "rolls back all changes" do
        expect { creator.update_or_create! }.to raise_error(Shopify::SaleCreator::OrderProcessingError)
        expect(Sale.count).to eq(0)
        expect(Customer.count).to eq(0)
        expect(ProductSale.count).to eq(0)
      end
    end

    context "when customer already exists" do
      let!(:existing_customer) do
        create(:customer,
          shopify_id: valid_parsed_order[:customer][:shopify_id],
          email: "old_email@example.com",
          first_name: "OldFirstName",
          last_name: "OldLastName",
          phone: "1234567890")
      end

      it "updates existing customer with new data" do
        expect {
          creator.update_or_create!
        }.not_to change(Customer, :count)

        existing_customer.reload
        expect(existing_customer.email).to eq(valid_parsed_order[:customer][:email])
        expect(existing_customer.first_name).to eq(valid_parsed_order[:customer][:first_name])
        expect(existing_customer.last_name).to eq(valid_parsed_order[:customer][:last_name])
        expect(existing_customer.phone).to eq(valid_parsed_order[:customer][:phone])
      end
    end
  end

  describe "#link_sale" do
    it "calls SaleLinker with the created sale" do
      sale_linker = instance_double(SaleLinker)
      expect(SaleLinker).to receive(:new).with(an_instance_of(Sale)).and_return(sale_linker)
      expect(sale_linker).to receive(:link).and_return([1, 2, 3])

      creator.update_or_create!
    end
  end

  describe "#notify_customers" do
    it "calls Notifier with the linked product IDs" do
      linked_ids = [1, 2, 3]
      sale_linker = instance_double(SaleLinker)
      allow(SaleLinker).to receive(:new).and_return(sale_linker)
      allow(sale_linker).to receive(:link).and_return(linked_ids)

      notifier = instance_double(Notifier)
      expect(Notifier).to receive(:new).with(purchased_product_ids: linked_ids).and_return(notifier)
      expect(notifier).to receive(:handle_product_purchase)

      creator.update_or_create!
    end
  end

  describe "#create_editions_for_product!" do
    it "creates editions for a product using EditionCreator" do
      product = create(:product)
      parsed_editions = [
        {title: "Edition 1", shopify_id: "ed1"},
        {title: "Edition 2", shopify_id: "ed2"}
      ]

      edition_creator = instance_double(Shopify::EditionCreator)
      expect(Shopify::EditionCreator).to receive(:new).twice.and_return(edition_creator)
      expect(edition_creator).to receive(:update_or_create!).twice

      creator.send(:create_editions_for_product!, parsed_editions, product)
    end
  end

  describe "transaction behavior" do
    context "when an error occurs during product creation" do
      before do
        allow_any_instance_of(Shopify::ProductCreator).to receive(:update_or_create!).and_raise(ActiveRecord::RecordInvalid.new(Product.new))
      end

      it "rolls back all changes including customer and sale" do
        expect { creator.update_or_create! }.to raise_error(Shopify::SaleCreator::OrderProcessingError)
        expect(Customer.count).to eq(0)
        expect(Sale.count).to eq(0)
      end
    end

    context "when an error occurs during edition creation" do
      before do
        allow_any_instance_of(Shopify::EditionCreator).to receive(:update_or_create!).and_raise(ActiveRecord::RecordInvalid.new(Edition.new))
      end

      it "rolls back all changes" do
        expect { creator.update_or_create! }.to raise_error(Shopify::SaleCreator::OrderProcessingError)
        expect(Customer.count).to eq(0)
        expect(Sale.count).to eq(0)
        expect(Product.count).to eq(0)
      end
    end
  end
end
