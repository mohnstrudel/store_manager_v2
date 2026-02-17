# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::ShopifyImporter do
  describe ".import!" do
    let(:parsed_payload) do
      {
        email: "test@example.com",
        first_name: "John",
        last_name: "Doe",
        phone: "+1234567890",
        store_info: {
          store_id: "gid://shopify/Customer/12345",
          ext_created_at: 1.day.ago.iso8601,
          ext_updated_at: 1.hour.ago.iso8601
        }
      }
    end

    context "when creating a new customer" do
      it "creates a new customer" do
        expect { described_class.import!(parsed_payload) }.to change(Customer, :count).by(1)
      end

      it "stores the customer email" do
        customer = described_class.import!(parsed_payload)
        expect(customer.email).to eq("test@example.com")
      end

      it "stores the customer first name" do
        customer = described_class.import!(parsed_payload)
        expect(customer.first_name).to eq("John")
      end

      it "stores the customer last name" do
        customer = described_class.import!(parsed_payload)
        expect(customer.last_name).to eq("Doe")
      end

      it "stores the customer phone" do
        customer = described_class.import!(parsed_payload)
        expect(customer.phone).to eq("+1234567890")
      end

      it "creates a Shopify store info record" do
        customer = described_class.import!(parsed_payload)
        expect(customer.shopify_info).to be_present
      end

      it "stores the Shopify store ID" do
        customer = described_class.import!(parsed_payload)
        expect(customer.shopify_info.store_id).to eq("gid://shopify/Customer/12345")
      end

      it "marks the store info as Shopify" do
        customer = described_class.import!(parsed_payload)
        expect(customer.shopify_info.shopify?).to be true
      end

      it "stores the external created at timestamp" do
        customer = described_class.import!(parsed_payload)
        expect(customer.shopify_info.ext_created_at).to be_within(2.seconds).of(1.day.ago)
      end

      it "stores the external updated at timestamp" do
        customer = described_class.import!(parsed_payload)
        expect(customer.shopify_info.ext_updated_at).to be_within(2.seconds).of(1.hour.ago)
      end

      it "records when the data was pulled" do
        customer = described_class.import!(parsed_payload)
        expect(customer.shopify_info.pull_time).to be_present
      end

      it "returns the created customer" do
        customer = described_class.import!(parsed_payload)
        expect(customer).to be_a(Customer)
      end

      it "persists the customer" do
        customer = described_class.import!(parsed_payload)
        expect(customer).to be_persisted
      end
    end

    context "when customer already exists" do
      let!(:existing_customer) do
        customer = create(
          :customer,
          email: "old_email@example.com",
          first_name: "OldFirstName",
          last_name: "OldLastName",
          phone: "9876543210"
        )
        customer.store_infos.create(store_name: :shopify, store_id: parsed_payload[:store_info][:store_id])
        customer
      end

      it "does not create a new customer" do
        expect { described_class.import!(parsed_payload) }.not_to change(Customer, :count)
      end

      it "updates the customer email" do
        described_class.import!(parsed_payload)
        expect(existing_customer.reload.email).to eq(parsed_payload[:email])
      end

      it "updates the customer first name" do
        described_class.import!(parsed_payload)
        expect(existing_customer.reload.first_name).to eq(parsed_payload[:first_name])
      end

      it "updates the customer last name" do
        described_class.import!(parsed_payload)
        expect(existing_customer.reload.last_name).to eq(parsed_payload[:last_name])
      end

      it "updates the customer phone" do
        described_class.import!(parsed_payload)
        expect(existing_customer.reload.phone).to eq(parsed_payload[:phone])
      end

      it "updates the external created at timestamp" do
        described_class.import!(parsed_payload)
        expect(existing_customer.shopify_info.reload.ext_created_at).to be_within(2.seconds).of(1.day.ago)
      end

      it "updates the external updated at timestamp" do
        described_class.import!(parsed_payload)
        expect(existing_customer.shopify_info.reload.ext_updated_at).to be_within(2.seconds).of(1.hour.ago)
      end

      it "returns the existing customer" do
        customer = described_class.import!(parsed_payload)
        expect(customer).to eq(existing_customer)
      end
    end

    context "when creating a guest customer without store_info" do
      let(:guest_payload) do
        {
          email: "guest@example.com",
          first_name: "Guest",
          last_name: "Customer"
        }
      end

      it "creates a customer" do
        expect { described_class.import!(guest_payload) }.to change(Customer, :count).by(1)
      end

      it "stores the customer email" do
        customer = described_class.import!(guest_payload)
        expect(customer.email).to eq("guest@example.com")
      end

      it "does not create a store info record" do
        customer = described_class.import!(guest_payload)
        expect(customer.shopify_info).to be_nil
      end
    end

    context "when attributes are nil" do
      let(:nil_payload) do
        {
          email: nil,
          first_name: nil,
          last_name: nil,
          phone: nil
        }
      end

      it "creates a customer with nil attributes" do
        expect { described_class.import!(nil_payload) }.to change(Customer, :count).by(1)
      end

      it "stores nil email" do
        customer = described_class.import!(nil_payload)
        expect(customer.email).to be_nil
      end

      it "stores nil first name" do
        customer = described_class.import!(nil_payload)
        expect(customer.first_name).to be_nil
      end

      it "stores nil last name" do
        customer = described_class.import!(nil_payload)
        expect(customer.last_name).to be_nil
      end

      it "stores nil phone" do
        customer = described_class.import!(nil_payload)
        expect(customer.phone).to be_nil
      end
    end

    context "when providing minimal customer data" do
      let(:minimal_payload) do
        {
          email: "minimal@example.com",
          store_info: {
            store_id: "gid://shopify/Customer/99999"
          }
        }
      end

      it "creates a customer" do
        expect { described_class.import!(minimal_payload) }.to change(Customer, :count).by(1)
      end

      it "stores the provided email" do
        customer = described_class.import!(minimal_payload)
        expect(customer.email).to eq("minimal@example.com")
      end

      it "leaves first name as nil" do
        customer = described_class.import!(minimal_payload)
        expect(customer.first_name).to be_nil
      end

      it "leaves last name as nil" do
        customer = described_class.import!(minimal_payload)
        expect(customer.last_name).to be_nil
      end

      it "leaves phone as nil" do
        customer = described_class.import!(minimal_payload)
        expect(customer.phone).to be_nil
      end
    end

    context "when the payload is invalid" do
      it "raises an error for a blank payload" do
        expect { described_class.import!({}) }.to raise_error(ArgumentError, /Parsed payload cannot be blank/)
      end

      it "raises an error for a nil payload" do
        expect { described_class.import!(nil) }.to raise_error(ArgumentError, /Parsed payload cannot be blank/)
      end

      it "successfully imports customer with minimal data (no validations on Customer model)" do
        # Customer model has no validations, so minimal data should succeed
        minimal_payload = {
          email: "minimal@example.com"
        }

        expect { described_class.import!(minimal_payload) }.not_to raise_error
        customer = Customer.find_by(email: "minimal@example.com")
        expect(customer).to be_present
      end

      it "successfully imports customer with only store_info data" do
        # Customer can be imported with just store_info, no other fields required
        store_only_payload = {
          store_info: {store_id: "gid://shopify/Customer/77777"}
        }

        expect { described_class.import!(store_only_payload) }.not_to raise_error
      end
    end
  end

  describe "#update_or_create!" do
    let(:parsed_payload) do
      {
        email: "test@example.com",
        first_name: "John",
        last_name: "Doe",
        store_info: {
          store_id: "gid://shopify/Customer/12345"
        }
      }
    end

    it "returns the customer" do
      customer = described_class.new(parsed_payload).update_or_create!
      expect(customer).to be_a(Customer)
    end

    it "creates a new customer" do
      expect { described_class.new(parsed_payload).update_or_create! }.to change(Customer, :count).by(1)
    end

    context "when customer already exists" do
      let!(:existing_customer) do
        customer = create(:customer, email: "old@example.com")
        customer.store_infos.create(store_name: :shopify, store_id: parsed_payload[:store_info][:store_id])
        customer
      end

      it "does not create a new customer" do
        expect { described_class.new(parsed_payload).update_or_create! }.not_to change(Customer, :count)
      end

      it "updates the existing customer" do
        described_class.new(parsed_payload).update_or_create!
        expect(existing_customer.reload.email).to eq(parsed_payload[:email])
      end
    end
  end
end
