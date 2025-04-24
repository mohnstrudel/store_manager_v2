# == Schema Information
#
# Table name: configs
#
#  id                    :bigint           not null, primary key
#  sales_hook_status     :integer          default("disabled")
#  shopify_products_sync :datetime
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
require "rails_helper"

RSpec.describe Config do
  context "when we use it to handle sales hook" do
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
end
