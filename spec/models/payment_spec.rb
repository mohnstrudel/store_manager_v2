# frozen_string_literal: true

# == Schema Information
#
# Table name: payments
#
#  id           :bigint           not null, primary key
#  payment_date :datetime         not null
#  value        :decimal(8, 2)    default(0.0)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  purchase_id  :bigint           not null
#
require "rails_helper"

RSpec.describe Payment do
  subject(:payment) { build(:payment) }

  describe "Validations" do
    it { is_expected.to validate_presence_of(:value) }
  end

  describe "Associations" do
    it { is_expected.to belong_to(:purchase).touch(true) }
  end

  describe "Callbacks" do
    describe "#update_purchase_paid_count" do
      let(:purchase) { create(:purchase, amount: 10, item_price: 100.0, paid: 0) }

      context "when creating a payment" do
        it "updates the purchase paid amount" do
          expect {
            create(:payment, purchase:, value: 150.0)
          }.to change { purchase.reload.paid }.from(0).to(150.0)
        end

        it "accumulates paid amount when multiple payments are created" do
          create(:payment, purchase:, value: 100.0)
          create(:payment, purchase:, value: 200.0)

          expect(purchase.reload.paid).to eq(300.0)
        end
      end

      context "when updating a payment" do
        let!(:payment) { create(:payment, purchase:, value: 100.0) }

        before { purchase.update!(paid: 100.0) }

        it "updates the purchase paid amount with the delta" do
          payment.update!(value: 150.0)
          expect(purchase.reload.paid).to eq(150.0)
        end

        it "handles value decrease correctly" do
          payment.update!(value: 50.0)
          expect(purchase.reload.paid).to eq(50.0)
        end

        it "does not update paid when value is unchanged" do
          expect {
            payment.update!(payment_date: 1.day.ago)
          }.not_to change { purchase.reload.paid }
        end
      end

      context "when destroying a payment" do
        let!(:payment) { create(:payment, purchase:, value: 200.0) }

        before { purchase.update!(paid: 200.0) }

        it "subtracts the payment value from purchase paid amount" do
          expect {
            payment.destroy
          }.to change { purchase.reload.paid }.from(200.0).to(0)
        end
      end

      context "when purchase already has paid amount" do
        before { purchase.update!(paid: 250.0) }

        it "adds to the existing paid amount" do
          expect {
            create(:payment, purchase:, value: 150.0)
          }.to change { purchase.reload.paid }.from(250.0).to(400.0)
        end
      end

      context "with concurrent payments" do
        it "handles concurrent payment creation correctly" do
          threads = []
          expected_total = 0

          5.times do |i|
            value = (i + 1) * 10.0
            expected_total += value
            threads << Thread.new do
              create(:payment, purchase:, value:)
            end
          end

          threads.each(&:join)
          expect(purchase.reload.paid).to eq(expected_total)
        end
      end
    end
  end

  describe "Configuration and Extensions" do
    describe "auditing" do
      it "is audited" do
        expect(described_class.auditing_enabled).to be true
      end

      it "is audited associated with purchase" do
        expect(described_class.audit_associated_with).to eq(:purchase)
      end
    end

    describe "HasAuditNotifications" do
      it "includes HasAuditNotifications concern" do
        expect(described_class).to include(HasAuditNotifications)
      end
    end
  end

  describe "Counter cache" do
    let(:purchase) { create(:purchase, payments_count: 0) }

    it "increments payments_count when payment is created" do
      expect {
        create(:payment, purchase:)
      }.to change { purchase.reload.payments_count }.from(0).to(1)
    end

    it "decrements payments_count when payment is destroyed" do
      payment = create(:payment, purchase:)
      expect {
        payment.destroy
      }.to change { purchase.reload.payments_count }.from(1).to(0)
    end
  end
end
