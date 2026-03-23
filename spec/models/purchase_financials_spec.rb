# frozen_string_literal: true

require "rails_helper"

RSpec.describe Purchase do
  let(:purchase) { create(:purchase, amount: 10, item_price: 100.0) }

  before do
    create(:payment, purchase:, value: 200.0)
    create(:payment, purchase:, value: 300.0)
  end

  describe "#paid" do
    it "returns the paid column value from database" do
      expect(purchase.paid).to eq(500.0)
    end

    it "returns default value 0 for new purchases" do
      new_purchase = create(:purchase, amount: 5, item_price: 50.0)

      expect(new_purchase.paid).to eq(0)
    end

    it "is updated when a payment is created" do
      purchase.update!(paid: 0)
      create(:payment, purchase:, value: 150.0)

      expect(purchase.reload.paid).to eq(150.0)
    end

    it "accumulates when multiple payments are created" do
      purchase.update!(paid: 0)
      create(:payment, purchase:, value: 100.0)
      create(:payment, purchase:, value: 200.0)

      expect(purchase.reload.paid).to eq(300.0)
    end
  end

  describe "#debt" do
    it "calculates remaining debt (cost_total - paid)" do
      purchase.update!(shipping_total: 200.0)

      expect(purchase.debt).to eq(700.0)
    end

    it "returns 0 when paid amount exceeds cost_total" do
      purchase.update!(paid: 1500.0)

      expect(purchase.debt).to eq(0)
    end
  end

  describe "#item_debt" do
    it "calculates debt per item" do
      allow(purchase).to receive(:debt).and_return(700.0)

      expect(purchase.item_debt).to eq(70.0)
    end

    context "when amount is zero" do
      before { purchase.amount = 0 }

      it "returns Infinity" do
        allow(purchase).to receive(:debt).and_return(700.0)

        expect(purchase.item_debt).to eq(Float::INFINITY)
      end
    end
  end

  describe "#item_paid" do
    it "calculates paid amount per item" do
      expect(purchase.item_paid).to eq(50.0)
    end

    context "when amount is zero" do
      before { purchase.amount = 0 }

      it "returns Infinity" do
        allow(purchase).to receive(:paid).and_return(500.0)

        expect(purchase.item_paid).to eq(Float::INFINITY)
      end
    end
  end

  describe "#progress" do
    it "calculates payment progress percentage" do
      purchase.update!(shipping_total: 200.0)

      expect(purchase.progress.round(2)).to eq(41.67)
    end

    it "returns 0 when cost_total is zero" do
      purchase.update!(amount: 0, item_price: 0, shipping_total: 0)

      expect(purchase.progress).to eq(0)
    end

    it "returns 100 when paid amount exceeds cost_total" do
      purchase.update!(paid: 1500.0, shipping_total: 200.0)

      expect(purchase.progress).to eq(100)
    end

    it "returns 100 when paid amount equals cost_total" do
      purchase.update!(paid: 1200.0, shipping_total: 200.0)

      expect(purchase.progress).to eq(100)
    end
  end

  describe "#cost_total" do
    it "calculates total cost including shipping" do
      purchase.update!(shipping_total: 50.0)

      expect(purchase.cost_total).to eq(1050.0)
    end
  end

  describe "#date" do
    let(:purchase_date) { Date.new(2023, 1, 1) }
    let(:created_at) { DateTime.new(2023, 1, 2) }

    it "returns purchase_date when present" do
      purchase.purchase_date = purchase_date

      expect(purchase.date).to eq(purchase_date)
    end

    it "returns created_at when purchase_date is nil" do
      purchase.purchase_date = nil
      purchase.created_at = created_at

      expect(purchase.date).to eq(created_at)
    end
  end

  describe "#unpaid?" do
    it "returns true when purchase has no payments" do
      purchase.payments.destroy_all
      purchase.update!(payments_count: 0)

      expect(purchase.unpaid?).to be true
    end

    it "returns false when purchase has payments" do
      purchase.update!(payments_count: 1)

      expect(purchase.unpaid?).to be false
    end
  end

  describe "Edge Cases and Error Conditions" do
    describe "division by zero in progress method" do
      it "returns 0 when cost_total is zero" do
        purchase.update!(amount: 0, item_price: 0, shipping_total: 0)

        expect(purchase.progress).to eq(0)
      end
    end

    describe "paid column default value" do
      it "returns 0 by default for new purchases" do
        new_purchase = create(:purchase)

        expect(new_purchase.paid).to eq(0)
      end
    end

    describe "zero amount in item_debt and item_paid methods" do
      let(:purchase) { create(:purchase, amount: 0) }

      it "returns Infinity in item_debt" do
        allow(purchase).to receive(:debt).and_return(100.0)

        expect(purchase.item_debt).to eq(Float::INFINITY)
      end

      it "returns Infinity in item_paid" do
        allow(purchase).to receive(:paid).and_return(100.0)

        expect(purchase.item_paid).to eq(Float::INFINITY)
      end
    end
  end
end
