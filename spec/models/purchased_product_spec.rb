# == Schema Information
#
# Table name: purchased_products
#
#  id              :bigint           not null, primary key
#  expenses        :decimal(8, 2)
#  height          :integer
#  length          :integer
#  shipping_price  :decimal(8, 2)
#  tracking_number :string
#  weight          :integer
#  width           :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_sale_id :bigint
#  purchase_id     :bigint
#  warehouse_id    :bigint           not null
#
require "rails_helper"

describe PurchasedProduct do
  describe "#name" do
    subject(:purchased_product) { create(:purchased_product) }

    it { expect(purchased_product.name).to eq(purchased_product.purchase.full_title) }
  end
end
