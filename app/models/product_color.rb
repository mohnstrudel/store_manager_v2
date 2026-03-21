# frozen_string_literal: true

# == Schema Information
#
# Table name: product_colors
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  color_id   :bigint
#  product_id :bigint
#
class ProductColor < ApplicationRecord
  include HasAuditNotifications

  audited

  db_belongs_to :product, inverse_of: :product_colors
  db_belongs_to :color, inverse_of: :product_colors
  has_many :store_infos, as: :storable, dependent: :destroy, inverse_of: :storable
end
