# frozen_string_literal: true

# == Schema Information
#
# Table name: customers
#
#  id         :bigint           not null, primary key
#  email      :string
#  first_name :string
#  last_name  :string
#  phone      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  shopify_id :string
#  woo_id     :string
#
require "rails_helper"

RSpec.describe Customer do
  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end

  describe ".woo_id_is_valid?" do
    it "returns true for numeric woo IDs" do
      expect(described_class.woo_id_is_valid?("123")).to be true
    end

    it "returns true for string woo IDs" do
      expect(described_class.woo_id_is_valid?("abc")).to be true
    end

    it "returns false for zero" do
      expect(described_class.woo_id_is_valid?(0)).to be false
    end

    it "returns false for string zero" do
      expect(described_class.woo_id_is_valid?("0")).to be false
    end

    it "returns false for empty string" do
      expect(described_class.woo_id_is_valid?("")).to be false
    end
  end

  describe "associations" do
    it "has many sales" do
      customer = create(:customer)
      sale1 = create(:sale, customer:)
      sale2 = create(:sale, customer:)

      expect(customer.sales).to include(sale1, sale2)
    end
  end

  describe "normalization" do
    it "downcases the email" do
      customer = create(:customer, email: "JOHN@EXAMPLE.COM")

      expect(customer.email).to eq("john@example.com")
    end

    it "handles nil email" do
      customer = create(:customer, email: nil)

      expect(customer.email).to be_nil
    end
  end

  describe "validations" do
    context "when customer is not a Shopify import" do
      let(:customer) { build(:customer, email: nil) }

      it "allows customer without email" do
        expect(customer).to be_valid
      end
    end
  end

  describe "search" do
    let!(:matching_customer) do
      create(
        :customer,
        email: "michele@example.com",
        first_name: "Michele",
        last_name: "Pomarico",
        phone: "+491729364665"
      )
    end
    let!(:other_customer) do
      create(
        :customer,
        email: "alice@example.com",
        first_name: "Alice",
        last_name: "Wonder",
        phone: "+15551234567"
      )
    end

    it "finds customers by prefixes from searchable fields" do
      aggregate_failures do
        expect(described_class.search_by("Mich")).to include(matching_customer)
        expect(described_class.search_by("Poma")).to include(matching_customer)
        expect(described_class.search_by("michele")).to include(matching_customer)
        expect(described_class.search_by("+4917")).to include(matching_customer)
      end
    end

    it "returns all customers when the query is blank" do
      expect(described_class.search_by("")).to match_array([matching_customer, other_customer])
    end

    it "returns no customers when nothing matches" do
      expect(described_class.search_by("nonexistent")).to be_empty
    end
  end
end
