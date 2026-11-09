# frozen_string_literal: true

# == Schema Information
#
# Table name: configs
#
#  id                    :bigint           not null, primary key
#  sales_hook_status     :integer          default(0)
#  shopify_products_sync :datetime
#  shopify_sales_sync    :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
require "rails_helper"

RSpec.describe Config do
  context "when we use it to handle sales hook" do
    before { described_class.disable_sales_hook }

    it "returns correct status" do
      expect(described_class.sales_hook_disabled?).to be true
    end

    it "enables" do
      described_class.enable_sales_hook
      expect(described_class.sales_hook_disabled?).to be false
    end

    it "disables" do
      described_class.disable_sales_hook
      expect(described_class.sales_hook_disabled?).to be true
    end
  end

  describe ".current" do
    it "creates the single config row on first use and reuses it" do
      described_class.delete_all

      expect { described_class.current }.to change(described_class, :count).from(0).to(1)
      expect { described_class.current }.not_to change(described_class, :count)
    end

    it "reads settings written by another process" do
      described_class.disable_sales_hook
      described_class.find(described_class.current.id).update!(sales_hook_status: :active)

      expect(described_class.sales_hook_disabled?).to be false
    end
  end

  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
