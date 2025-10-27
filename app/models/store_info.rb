# == Schema Information
#
# Table name: store_infos
#
#  id               :bigint           not null, primary key
#  name             :integer          default("not_assigned"), not null
#  pull_time        :datetime
#  push_time        :datetime
#  slug             :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  product_id       :bigint           not null
#  store_product_id :string
#
class StoreInfo < ApplicationRecord
  enum :name, {
    not_assigned: 0,
    shopify: 1,
    woo: 2
  }, default: :not_assigned

  db_belongs_to :product

  def page_url
    "https://handsomecake.com/products/#{slug}"
  end
end
