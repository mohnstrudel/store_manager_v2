# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_items
#
#  id                   :bigint           not null, primary key
#  expected_revenue     :decimal(8, 2)
#  outstanding_revenue  :decimal(8, 2)
#  price                :decimal(8, 2)
#  purchase_items_count :integer          default(0), not null
#  qty                  :integer
#  received_revenue     :decimal(8, 2)
#  refunded_revenue     :decimal(8, 2)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  origin_sale_item_id  :bigint
#  product_id           :bigint           not null
#  sale_id              :bigint           not null
#  shopify_id           :string
#  variant_id           :bigint
#  woo_id               :string
#
require "rails_helper"

RSpec.describe SaleItem do
  describe "auditing" do
    it "is audited" do
      expect(described_class.auditing_enabled).to be true
    end
  end
end
