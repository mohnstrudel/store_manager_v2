# frozen_string_literal: true
require "rails_helper"

describe SalePolicy do
  subject { described_class.new(user, record) }

  let(:record) { instance_double(Sale) }
  let(:user) { User.new }

  context "when user is admin" do
    let(:user) { User.new(role: "admin") }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:pull) }
    it { is_expected.to permit_action(:link_purchase_items) }
  end

  context "when user is manager" do
    let(:user) { User.new(role: "manager") }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:pull) }
  end

  context "when user is support" do
    let(:user) { User.new(role: "support") }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:pull) }
    it { is_expected.to forbid_action(:link_purchase_items) }
  end

  context "when user is guest" do
    let(:user) { User.new(role: "guest") }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:pull) }
    it { is_expected.to forbid_action(:link_purchase_items) }
  end
end
