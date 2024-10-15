# == Schema Information
#
# Table name: purchased_products
#
#  id              :bigint           not null, primary key
#  expenses        :decimal(8, 2)
#  height          :integer
#  length          :integer
#  shipping_price  :decimal(8, 2)
#  weight          :integer
#  width           :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_sale_id :bigint
#  purchase_id     :bigint
#  warehouse_id    :bigint           not null
#
require "rails_helper"

RSpec.describe PurchasedProduct, type: :model do
  describe "#name" do
    subject(:purchased_product) { create(:purchased_product) }

    it { expect(purchased_product.name).to eq(purchased_product.purchase.full_title) }
  end
end
