# == Schema Information
#
# Table name: store_infos
#
#  id            :bigint           not null, primary key
#  price         :decimal(8, 2)    default(0.0), not null
#  pull_time     :datetime
#  push_time     :datetime
#  slug          :string
#  storable_type :string           not null
#  store_name    :integer          default("not_assigned"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  storable_id   :bigint           not null
#  store_id      :string
#
class StoreInfo < ApplicationRecord
  enum :store_name, {
    not_assigned: 0,
    shopify: 1,
    woo: 2
  }, default: :not_assigned

  belongs_to :storable, polymorphic: true

  validates :store_name, uniqueness: {
    scope: [:storable_type, :storable_id],
    message: "Store name must be unique"
  }

  def page_url_for(store_name)
    case store_name
    when :shopify
      "https://handsomecake.com/products/#{slug}"
    when :woo
      "https://store.handsomecake.com/product/#{slug}"
    end
  end
end
