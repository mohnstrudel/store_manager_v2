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

  describe "#name_and_email" do
    context "when customer has full name and email" do
      let(:customer) { build(:customer, first_name: "John", last_name: "Doe", email: "john@example.com") }

      it "returns the full name and email" do
        expect(customer.name_and_email).to eq("John Doe — john@example.com")
      end
    end

    context "when customer has only email" do
      let(:customer) { build(:customer, email: "john@example.com") }

      it "returns only the email" do
        expect(customer.name_and_email).to eq("john@example.com")
      end
    end

    context "when customer has only name" do
      let(:customer) { build(:customer, first_name: "John", last_name: "Doe") }

      it "returns only the full name" do
        expect(customer.name_and_email).to eq("John Doe")
      end
    end

    context "when customer has neither name nor email" do
      let(:customer) { build(:customer, first_name: nil, last_name: nil, email: nil) }

      it "returns an empty string" do
        expect(customer.name_and_email).to eq("")
      end
    end
  end

  describe "#full_name" do
    context "when customer has first and last name" do
      let(:customer) { build(:customer, first_name: "John", last_name: "Doe") }

      it "returns the concatenated name" do
        expect(customer.full_name).to eq("John Doe")
      end
    end

    context "when customer has only first name" do
      let(:customer) { build(:customer, first_name: "John", last_name: nil) }

      it "returns first name with space" do
        expect(customer.full_name).to eq("John ")
      end
    end

    context "when customer has only last name" do
      let(:customer) { build(:customer, first_name: nil, last_name: "Doe") }

      it "returns space with last name" do
        expect(customer.full_name).to eq(" Doe")
      end
    end
  end

  describe "#title" do
    it "returns the full name" do
      customer = build(:customer, first_name: "John", last_name: "Doe")
      expect(customer.title).to eq("John Doe")
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

  describe "callbacks" do
    describe "#downcase_email" do
      it "downcases the email before save" do
        customer = create(:customer, email: "JOHN@EXAMPLE.COM")

        expect(customer.email).to eq("john@example.com")
      end

      it "handles nil email" do
        customer = create(:customer, email: nil)

        expect(customer.email).to be_nil
      end
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
end
