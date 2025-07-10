# == Schema Information
#
# Table name: sale_items
#
#  id                   :bigint           not null, primary key
#  price                :decimal(8, 2)
#  purchase_items_count :integer          default(0), not null
#  qty                  :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  edition_id           :bigint
#  product_id           :bigint           not null
#  sale_id              :bigint           not null
#  shopify_id           :string
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
