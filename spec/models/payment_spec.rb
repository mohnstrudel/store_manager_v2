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
