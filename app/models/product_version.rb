# frozen_string_literal: true

# == Schema Information
#
# Table name: product_versions
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  product_id :bigint
#  version_id :bigint
#
class ProductVersion < ApplicationRecord
  include HasAuditNotifications

  audited

  db_belongs_to :product, inverse_of: :product_versions
  db_belongs_to :version, inverse_of: :product_versions
  has_many :store_infos, as: :storable, dependent: :destroy, inverse_of: :storable
end
