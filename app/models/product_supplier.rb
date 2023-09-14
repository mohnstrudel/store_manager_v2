# == Schema Information
#
# Table name: product_suppliers
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  product_id  :bigint
#  supplier_id :bigint
#
class ProductSupplier < ApplicationRecord
  belongs_to :product
  belongs_to :supplier
end
