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
  after_save ->(product_version) { product_version.product.set_full_title }

  db_belongs_to :product
  db_belongs_to :version
end
