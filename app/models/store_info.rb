# == Schema Information
#
# Table name: store_infos
#
#  id               :bigint           not null, primary key
#  name             :integer          default("not_assigned"), not null
#  page_url         :string
#  pull_status      :integer          default("fail")
#  pull_time        :datetime
#  push_status      :integer          default("fail")
#  push_time        :datetime
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
  enum :push_status, {
    pending: 0,
    done: 1
  }, default: :pending, suffix: true
  enum :pull_status, {
    pending: 0,
    done: 1
  }, default: :pending, suffix: true

  db_belongs_to :product
end
