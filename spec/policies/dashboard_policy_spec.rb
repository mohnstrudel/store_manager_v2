# frozen_string_literal: true
require "rails_helper"

describe DashboardPolicy do
  subject { described_class.new(user, record) }

  let(:record) { instance_double(DashboardController) }
  let(:user) { User.new }

  context "when user is admin" do
    let(:user) { User.new(role: "admin") }

    it { is_expected.to permit_action(:debts) }
    it { is_expected.to permit_action(:pull_last_orders) }
    it { is_expected.to permit_action(:noop) }
  end

  context "when user is manager" do
    let(:user) { User.new(role: "manager") }

    it { is_expected.to permit_action(:debts) }
    it { is_expected.to permit_action(:pull_last_orders) }
    it { is_expected.to permit_action(:noop) }
  end

  context "when user is support" do
    let(:user) { User.new(role: "support") }

    it { is_expected.to forbid_action(:debts) }
    it { is_expected.to permit_action(:pull_last_orders) }
    it { is_expected.to permit_action(:noop) }
  end

  context "when user is guest" do
    let(:user) { User.new(role: "guest") }

    it { is_expected.to forbid_action(:debts) }
    it { is_expected.to forbid_action(:pull_last_orders) }
    it { is_expected.to permit_action(:noop) }
  end
end
