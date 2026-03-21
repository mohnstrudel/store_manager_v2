# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer::Identity do
  describe "#name_and_email" do
    context "when customer has full name and email" do
      let(:customer) { build(:customer, first_name: "John", last_name: "Doe", email: "john@example.com") }

      it "returns the full name and email" do
        expect(customer.name_and_email).to eq("John Doe — john@example.com")
      end
    end

    context "when customer has only email" do
      let(:customer) { build(:customer, first_name: nil, last_name: nil, email: "john@example.com") }

      it "returns only the email" do
        expect(customer.name_and_email).to eq("john@example.com")
      end
    end

    context "when customer has only name" do
      let(:customer) { build(:customer, first_name: "John", last_name: "Doe", email: nil) }

      it "returns only the full name" do
        expect(customer.name_and_email).to eq("John Doe")
      end
    end

    context "when customer has neither name nor email" do
      let(:customer) { build_stubbed(:customer, first_name: nil, last_name: nil, email: nil) }

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

      it "returns first name without trailing space" do
        expect(customer.full_name).to eq("John")
      end
    end

    context "when customer has only last name" do
      let(:customer) { build(:customer, first_name: nil, last_name: "Doe") }

      it "returns last name without leading space" do
        expect(customer.full_name).to eq("Doe")
      end
    end
  end

  describe "#title" do
    it "returns the full name" do
      customer = build(:customer, first_name: "John", last_name: "Doe")
      expect(customer.title).to eq("John Doe")
    end
  end
end
