# frozen_string_literal: true

require "rails_helper"

RSpec.describe OperationalExpensePolicy do
  subject(:policy) { described_class.new(user, OperationalExpense.new) }

  context "when the user is an admin" do
    let(:user) { create(:user, :admin) }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:destroy) }
  end

  context "when the user is a manager" do
    let(:user) { create(:user, :manager) }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe described_class::Scope do
    it "resolves all records for admins" do
      scope = described_class.new(create(:user, :admin), OperationalExpense.all)

      expect(scope.resolve).to eq(OperationalExpense.all)
    end

    it "resolves no records for managers" do
      scope = described_class.new(create(:user, :manager), OperationalExpense.all)

      expect(scope.resolve).to be_empty
    end
  end
end
