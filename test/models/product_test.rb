# == Schema Information
#
# Table name: products
#
#  id           :bigint           not null, primary key
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  brand_id     :bigint           not null
#  color_id     :bigint           not null
#  franchise_id :bigint           not null
#  shape_id     :bigint           not null
#  size_id      :bigint           not null
#  supplier_id  :bigint           not null
#  version_id   :bigint           not null
#
require "test_helper"

class ProductTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
