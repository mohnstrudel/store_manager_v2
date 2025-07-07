require "rails_helper"

describe SessionPolicy do
  subject { described_class.new(user, record) }

  let(:record) { instance_double(Session) }
  let(:user) { User.new }

  context "when user is admin" do
    let(:user) { User.new(role: "admin") }

    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:destroy) }
  end

  context "when user is manager" do
    let(:user) { User.new(role: "manager") }

    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:destroy) }
  end

  context "when user is support" do
    let(:user) { User.new(role: "support") }

    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:destroy) }
  end

  context "when user is guest" do
    let(:user) { User.new(role: "guest") }

    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:destroy) }
  end
end
