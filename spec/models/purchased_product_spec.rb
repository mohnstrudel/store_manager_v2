# == Schema Information
#
# Table name: warehouse_products
#
#  id              :bigint           not null, primary key
#  height          :integer
#  length          :integer
#  price           :decimal(8, 2)
#  shipping_price  :decimal(8, 2)
#  tracking_number :string
#  weight          :integer
#  width           :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  product_id      :bigint           not null
#  warehouse_id    :bigint           not null
#
require "rails_helper"

RSpec.describe PurchasedProduct, type: :model do
  describe "#name" do
    subject(:purchased_product) { create(:purchased_product) }

    it { expect(purchased_product.name).to eq(purchased_product.purchase.full_title) }
  end
end
