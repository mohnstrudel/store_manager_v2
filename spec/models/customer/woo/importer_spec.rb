# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Woo::Importer do
  let(:parsed_woo_orders) {
    JSON.parse(file_fixture("parsed_orders.json").read, symbolize_names: true)
  }

  describe ".import!" do
    context "when we receive a valid woo_id" do
      it "returns existing customer" do
        parsed_customer = parsed_woo_orders.first[:customer]
        existing_customer = create(
          :customer,
          email: "#{SecureRandom.hex(5)}@mail.com",
          woo_store_id: parsed_customer[:woo_id]
        )
        parsed_customer_id = described_class.import!(parsed_customer).id

        expect(parsed_customer_id).to eq(existing_customer.id)
      end

      it "creates a customer with only Woo store information" do
        customer = described_class.import!({
          email: nil,
          first_name: nil,
          last_name: nil,
          phone: nil,
          woo_id: "12345"
        })

        expect(customer.woo_info.store_id).to eq("12345")
      end

      it "treats a non-numeric woo_id as valid" do
        customer = described_class.import!({email: nil, woo_id: "abc"})

        expect(customer.woo_info.store_id).to eq("abc")
      end
    end

    context "when we receive invalid woo_id" do
      let(:parsed_customer) { parsed_woo_orders.last[:customer] }

      let(:existing_customer) {
        create(
          :customer,
          email: parsed_customer[:email],
          woo_store_id: nil
        )
      }

      it "returns existing customer if woo_id == 0" do
        existing_customer_id = existing_customer.id
        parsed_customer_id = described_class.import!(parsed_customer.merge(woo_id: 0)).id

        expect(parsed_customer_id).to eq(existing_customer_id)
      end

      it "returns existing customer if woo_id == '0'" do
        existing_customer_id = existing_customer.id
        parsed_customer_id = described_class.import!(parsed_customer.merge(woo_id: "0")).id

        expect(parsed_customer_id).to eq(existing_customer_id)
      end

      it "returns existing customer if woo_id == ''" do
        existing_customer_id = existing_customer.id
        parsed_customer_id = described_class.import!(parsed_customer.merge(woo_id: "")).id

        expect(parsed_customer_id).to eq(existing_customer_id)
      end
    end
  end
end
