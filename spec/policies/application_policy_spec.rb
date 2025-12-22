# frozen_string_literal: true
require "rails_helper"

describe ApplicationPolicy do
  subject { described_class.new(user, record) }

  # Any record, since the policy is generic
  let(:record) { instance_double("AnyRecord") }
  let(:user) { User.new }

  context "when user is admin" do
    let(:user) { User.new(role: "admin") }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to permit_action(:edit) }
    it { is_expected.to permit_action(:destroy) }
  end

  context "when user is manager" do
    let(:user) { User.new(role: "manager") }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:new) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:edit) }
    it { is_expected.to forbid_action(:destroy) }
  end

  context "when user is support" do
    let(:user) { User.new(role: "support") }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:new) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:edit) }
    it { is_expected.to forbid_action(:destroy) }
  end

  context "when user is nil (guest)" do
    let(:user) { nil }

    it { is_expected.to forbid_action(:index) }
    it { is_expected.to forbid_action(:show) }
    it { is_expected.to forbid_action(:create) }
    it { is_expected.to forbid_action(:new) }
    it { is_expected.to forbid_action(:update) }
    it { is_expected.to forbid_action(:edit) }
    it { is_expected.to forbid_action(:destroy) }
  end

  describe "Scope" do
    # Pundit needs a real model
    let(:scope) { Pundit.policy_scope!(user, Product) }
    let!(:products) { create_list(:product, 2) }

    context "when user is admin" do
      let(:user) { create(:user, :admin) }

      it "returns all products" do
        expect(scope.to_a).to match_array(products)
      end
    end

    context "when user is manager" do
      let(:user) { create(:user, :manager) }

      it "returns all products" do
        expect(scope.to_a).to match_array(products)
      end
    end

    context "when user is support" do
      let(:user) { create(:user, :support) }

      it "returns all products" do
        expect(scope.to_a).to match_array(products)
      end
    end

    context "when user is guest" do
      let(:user) { create(:user) }

      it "returns no products" do
        expect(scope.to_a).to be_empty
      end
    end
  end
end
