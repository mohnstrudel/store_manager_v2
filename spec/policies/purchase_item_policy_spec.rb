require "rails_helper"

describe PurchaseItemPolicy do
  subject { described_class.new(user, record) }

  let(:record) { instance_double(PurchaseItem) }
  let(:user) { User.new }

  context "when user is admin" do
    let(:user) { User.new(role: "admin") }

    it { is_expected.to permit_action(:move) }
    it { is_expected.to permit_action(:unlink) }
    it { is_expected.to permit_action(:edit_tracking_number) }
    it { is_expected.to permit_action(:cancel_tracking_number) }
    it { is_expected.to permit_action(:update_tracking_number) }
    it { is_expected.to permit_action(:edit_shipping_company) }
    it { is_expected.to permit_action(:cancel_edit_shipping_company) }
    it { is_expected.to permit_action(:update_shipping_company) }
  end

  context "when user is manager" do
    let(:user) { User.new(role: "manager") }

    it { is_expected.to forbid_action(:move) }
    it { is_expected.to forbid_action(:unlink) }
    it { is_expected.to forbid_action(:edit_tracking_number) }
    it { is_expected.to forbid_action(:cancel_tracking_number) }
    it { is_expected.to forbid_action(:update_tracking_number) }
    it { is_expected.to forbid_action(:edit_shipping_company) }
    it { is_expected.to forbid_action(:cancel_edit_shipping_company) }
    it { is_expected.to forbid_action(:update_shipping_company) }
  end

  context "when user is support" do
    let(:user) { User.new(role: "support") }

    it { is_expected.to forbid_action(:move) }
    it { is_expected.to forbid_action(:unlink) }
    it { is_expected.to forbid_action(:edit_tracking_number) }
    it { is_expected.to forbid_action(:cancel_tracking_number) }
    it { is_expected.to forbid_action(:update_tracking_number) }
    it { is_expected.to forbid_action(:edit_shipping_company) }
    it { is_expected.to forbid_action(:cancel_edit_shipping_company) }
    it { is_expected.to forbid_action(:update_shipping_company) }
  end

  context "when user is guest" do
    let(:user) { User.new(role: "guest") }

    it { is_expected.to forbid_action(:move) }
    it { is_expected.to forbid_action(:unlink) }
    it { is_expected.to forbid_action(:edit_tracking_number) }
    it { is_expected.to forbid_action(:cancel_tracking_number) }
    it { is_expected.to forbid_action(:update_tracking_number) }
    it { is_expected.to forbid_action(:edit_shipping_company) }
    it { is_expected.to forbid_action(:cancel_edit_shipping_company) }
    it { is_expected.to forbid_action(:update_shipping_company) }
  end
end
