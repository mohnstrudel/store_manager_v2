# frozen_string_literal: true

# == Schema Information
#
# Table name: product_sizes
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :bigint
#  size_id    :bigint
#
class ProductSize < ApplicationRecord
  include HasAuditNotifications

  audited

  db_belongs_to :product, inverse_of: :product_sizes
  db_belongs_to :size, inverse_of: :product_sizes

  has_many :store_infos, as: :storable, dependent: :destroy, inverse_of: :storable
end
