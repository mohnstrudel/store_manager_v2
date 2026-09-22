# frozen_string_literal: true

require "rails_helper"

describe PurchaseExpensePolicy do
  subject { described_class.new(user, record) }

  let(:record) { instance_double(PurchaseExpense) }

  context "when user is admin" do
    let(:user) { User.new(role: "admin") }

    it { is_expected.to permit_actions(%i[create new update edit destroy]) }
  end

  context "when user is manager" do
    let(:user) { User.new(role: "manager") }

    it { is_expected.to forbid_actions(%i[create new update edit destroy]) }
  end

  context "when user is support" do
    let(:user) { User.new(role: "support") }

    it { is_expected.to forbid_actions(%i[create new update edit destroy]) }
  end

  context "when user is guest" do
    let(:user) { User.new(role: "guest") }

    it { is_expected.to forbid_actions(%i[create new update edit destroy]) }
  end
end
