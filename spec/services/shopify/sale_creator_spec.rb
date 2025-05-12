require "rails_helper"

RSpec.describe Shopify::SaleCreator do
  let(:parsed_orders) { instance_eval(file_fixture("shopify_parsed_orders.rb").read) }
  let(:valid_parsed_order) { parsed_orders.first }
  let(:creator) { described_class.new(valid_parsed_order) }
  let(:products_size) { valid_parsed_order[:product_sales].count { |ps| ps.key?(:product) } }

  describe "#update_or_create" do
    context "with invalid input" do
      it "raises error when parsed_order is not a Hash" do
        expect { described_class.new(nil).update_or_create! }.to raise_error(ArgumentError, "Order data must be a Hash")
      end

      it "raises error when parsed_order is blank" do
        expect { described_class.new({}).update_or_create! }.to raise_error(ArgumentError, "Order data is required")
      end

      it "raises error when customer data is missing" do
        invalid_order = valid_parsed_order.dup
        invalid_order[:customer] = nil
        expect { described_class.new(invalid_order).update_or_create! }.to raise_error(ArgumentError, "Customer data is required")
      end

      it "raises error when sale data is missing" do
        invalid_order = valid_parsed_order.dup
        invalid_order[:sale] = nil
        expect { described_class.new(invalid_order).update_or_create! }.to raise_error(ArgumentError, "Sale data is required")
      end

      it "raises error when product_sales is missing" do
        invalid_order = valid_parsed_order.dup
        invalid_order[:product_sales] = nil
        expect { described_class.new(invalid_order).update_or_create! }.to raise_error(ArgumentError, "Product sales data is required")
      end
    end

    context "when creating a new sale" do
      it "creates all required records" do
        expect { creator.update_or_create! }.to change(Sale, :count).by(1)
          .and change(Customer, :count).by(1)
          .and change(ProductSale, :count).by(1)
          .and change(Product, :count).by(products_size)
          .and change(Variation, :count).by(2)
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

    context "when variation already exists" do
      let(:parsed_order) { valid_parsed_order }
      let!(:existing_variation) { create(:variation, shopify_id: parsed_order[:product_sales].first[:shopify_variation_id]) }

      it "uses existing variation" do
        expect { creator.update_or_create! }.not_to change(Variation, :count)
        expect(ProductSale.last.variation).to eq(existing_variation)
      end
    end

    context "when product sale is corrupted" do
      let(:parsed_order_corrupted) do
        order = valid_parsed_order.deep_dup
        order[:product_sales].first[:shopify_variation_id] = nil
        order[:product_sales].first[:shopify_product_id] = nil
        order[:product_sales].first[:variation_title] = nil
        order
      end
      let(:creator_corrupted) { described_class.new(parsed_order_corrupted) }

      it "does not create a new variation when variation_title is missing" do
        expect { creator_corrupted.update_or_create! }.not_to change(Variation, :count)
      end

      it "still creates the product sale without a variation" do
        expect { creator_corrupted.update_or_create! }.to change(ProductSale, :count).by(1)
        expect(ProductSale.last.variation).to be_nil
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
end
