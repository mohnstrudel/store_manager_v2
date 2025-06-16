require "rails_helper"

RSpec.describe Shopify::SaleCreator do
  let(:parsed_orders) { instance_eval(file_fixture("shopify_parsed_orders.rb").read) }
  let(:valid_parsed_order) { parsed_orders.first }
  let(:creator) { described_class.new(parsed_item: valid_parsed_order) }
  let(:products_size) { valid_parsed_order[:product_sales].count { |ps| ps.key?(:product) } }

  describe "#update_or_create!" do
    context "with invalid input" do
      it "raises error when parsed_order is not a Hash" do
        expect { described_class.new(parsed_item: nil).update_or_create! }.to raise_error(ArgumentError, "parsed_item must be a Hash")
      end

      it "raises error when parsed_order is blank" do
        expect { described_class.new(parsed_item: {}).update_or_create! }.to raise_error(ArgumentError, "parsed_item cannot be blank")
      end

      it "raises error when customer data is missing" do
        invalid_order = valid_parsed_order.dup
        invalid_order[:customer] = nil
        expect { described_class.new(parsed_item: invalid_order).update_or_create! }.to raise_error(ArgumentError, "parsed_item[:customer] cannot be blank")
      end

      it "raises error when sale data is missing" do
        invalid_order = valid_parsed_order.dup
        invalid_order[:sale] = nil
        expect { described_class.new(parsed_item: invalid_order).update_or_create! }.to raise_error(ArgumentError, "parsed_item[:sale] cannot be blank")
      end

      it "raises error when product_sales is missing" do
        invalid_order = valid_parsed_order.dup
        invalid_order[:product_sales] = nil
        expect { described_class.new(parsed_item: invalid_order).update_or_create! }.to raise_error(ArgumentError, "parsed_item[:product_sales] cannot be blank")
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

      it "updates existing sale with new data" do
        # Modify the parsed order data
        modified_order = valid_parsed_order.deep_dup
        modified_order[:sale][:status] = "completed"
        modified_order[:sale][:closed] = true

        # Create a new creator with modified data
        modified_creator = described_class.new(parsed_item: modified_order)

        # Update the existing sale
        modified_creator.update_or_create!

        # Verify the sale was updated
        sale = Sale.find_by(shopify_id: valid_parsed_order[:sale][:shopify_id])
        expect(sale.status).to eq("completed")
        expect(sale.closed).to be true
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

    context "when creating new edition" do
      let(:parsed_order_with_new_edition) do
        order = valid_parsed_order.deep_dup
        order[:product_sales].first.merge!(
          edition_title: "New Edition",
          shopify_edition_id: nil,
          shopify_product_id: nil,
          full_title: "Test Product",
          product: nil
        )
        order
      end
      let(:creator_with_new_edition) { described_class.new(parsed_item: parsed_order_with_new_edition) }

      it "creates new edition with correct title" do
        product = create(:product)
        product_creator = instance_double(Shopify::ProductFromTitleCreator)
        allow(Shopify::ProductFromTitleCreator).to receive(:new).and_return(product_creator)
        allow(product_creator).to receive(:call).and_return(product)

        expect { creator_with_new_edition.update_or_create! }.to change(Edition, :count).by(1)
        expect(Edition.last.version.value).to eq("New Edition")
        expect(Edition.last.product).to eq(product)
      end
    end

    context "when creating edition with multiple attributes" do
      let(:parsed_order_with_complex_edition) do
        order = valid_parsed_order.deep_dup
        order[:product_sales].first.merge!(
          edition_title: "1:4 | New Edition | Red",
          shopify_edition_id: nil,
          shopify_product_id: nil,
          full_title: "Test Product",
          product: nil
        )
        order
      end
      let(:creator_with_complex_edition) { described_class.new(parsed_item: parsed_order_with_complex_edition) }

      it "creates new edition with multiple attributes" do
        product = create(:product)
        product_creator = instance_double(Shopify::ProductFromTitleCreator)
        allow(Shopify::ProductFromTitleCreator).to receive(:new).and_return(product_creator)
        allow(product_creator).to receive(:call).and_return(product)

        expect { creator_with_complex_edition.update_or_create! }.to change(Edition, :count).by(1)
        expect(Edition.last.title).to eq("1:4 | New Edition | Red")
        expect(Edition.last.product).to eq(product)
      end
    end

    context "when edition creation fails" do
      let(:parsed_order_with_invalid_edition) do
        order = valid_parsed_order.deep_dup
        order[:product_sales].first.merge!(
          edition_title: "Invalid Edition",
          shopify_edition_id: "gid://shopify/ProductVariant/12345",
          shopify_product_id: "gid://shopify/Product/67890",
          product: {
            title: "Test Product",
            editions: [{
              shopify_id: "gid://shopify/ProductVariant/12345",
              title: "Invalid Edition"
            }]
          }
        )
        order
      end
      let(:creator_with_invalid_edition) { described_class.new(parsed_item: parsed_order_with_invalid_edition) }

      it "rolls back all changes when edition creation fails" do
        product = create(:product)
        product_creator = instance_double(Shopify::ProductCreator)
        allow(Shopify::ProductCreator).to receive(:new).and_return(product_creator)
        allow(product_creator).to receive(:update_or_create!).and_return(product)

        edition_creator = instance_double(Shopify::EditionCreator)
        allow(Shopify::EditionCreator).to receive(:new).and_return(edition_creator)
        allow(edition_creator).to receive(:update_or_create!).and_raise(ActiveRecord::RecordInvalid.new(Edition.new))

        expect { creator_with_invalid_edition.update_or_create! }.to raise_error(Shopify::SaleCreator::OrderProcessingError)
        expect(Edition.count).to eq(0)
        expect(ProductSale.count).to eq(0)
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

    context "when product already exists" do
      let!(:existing_product) do
        create(:product,
          shopify_id: valid_parsed_order[:product_sales].first[:shopify_product_id],
          title: "Old Product Title")
      end
    end

    context "when product_sale already exists" do
      let!(:existing_sale) { create(:sale, shopify_id: valid_parsed_order[:sale][:shopify_id]) }
      let!(:existing_product) { create(:product, shopify_id: valid_parsed_order[:product_sales].first[:shopify_product_id]) }
      let!(:existing_edition) { create(:edition, shopify_id: valid_parsed_order[:product_sales].first[:shopify_edition_id]) }
      let!(:existing_product_sale) do
        create(:product_sale,
          shopify_id: valid_parsed_order[:product_sales].first[:shopify_id],
          price: "500.00",
          qty: 1,
          sale: existing_sale,
          product: existing_product,
          edition: existing_edition)
      end

      it "updates existing product_sale with new data" do
        # Modify the parsed order data
        modified_order = valid_parsed_order.deep_dup
        modified_order[:product_sales].first[:price] = "600.00"
        modified_order[:product_sales].first[:qty] = 2

        modified_creator = described_class.new(parsed_item: modified_order)

        expect {
          modified_creator.update_or_create!
        }.not_to change(ProductSale, :count)

        existing_product_sale.reload
        expect(existing_product_sale.price).to eq(BigDecimal("600.00"))
        expect(existing_product_sale.qty).to eq(2)
      end
    end

    context "when linking purchased products" do
      let(:sale) { create(:sale) }
      let(:product) { create(:product) }
      let(:purchase) { create(:purchase, product: product, amount: 3) }
      let!(:purchased_products) { create_list(:purchased_product, 3, purchase: purchase) }
      let!(:product_sale) { create(:product_sale, sale: sale, product: product, qty: 2) }

      it "links purchased products to the sale" do
        allow(Sale).to receive(:find_by).and_return(sale)
        allow(sale).to receive(:link_with_purchased_products).and_return(purchased_products.map(&:id))

        creator.update_or_create!

        expect(sale).to have_received(:link_with_purchased_products)
      end

      it "notifies customers about linked products" do
        allow(Sale).to receive(:find_by).and_return(sale)
        allow(sale).to receive(:link_with_purchased_products).and_return(purchased_products.map(&:id))

        notifier = instance_double(PurchasedNotifier)
        expect(PurchasedNotifier).to receive(:new).with(purchased_product_ids: purchased_products.map(&:id)).and_return(notifier)
        expect(notifier).to receive(:handle_product_purchase)

        creator.update_or_create!
      end
    end
  end
end
