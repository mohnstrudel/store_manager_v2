# frozen_string_literal: true

require "rails_helper"

describe ExpenseRatePolicy do
  subject { described_class.new(user, record) }

  let(:record) { instance_double(ExpenseRate) }

  context "when user is admin" do
    let(:user) { User.new(role: "admin") }

    it { is_expected.to permit_actions(%i[index show create new update edit destroy]) }
  end

  context "when user is manager" do
    let(:user) { User.new(role: "manager") }

    it { is_expected.to forbid_actions(%i[index show create new update edit destroy]) }
  end

  context "when user is support" do
    let(:user) { User.new(role: "support") }

    it { is_expected.to forbid_actions(%i[index show create new update edit destroy]) }
  end

  context "when user is guest" do
    let(:user) { User.new(role: "guest") }

    it { is_expected.to forbid_actions(%i[index show create new update edit destroy]) }
  end

  describe described_class::Scope do
    it "resolves all records for admins" do
      scope = described_class.new(User.new(role: "admin"), ExpenseRate.all)

      expect(scope.resolve).to eq(ExpenseRate.all)
    end

    it "resolves no records for managers" do
      scope = described_class.new(User.new(role: "manager"), ExpenseRate.all)

      expect(scope.resolve).to be_empty
    end
  end
end
