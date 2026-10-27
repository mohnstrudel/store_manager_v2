# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_taggings
#
#  id           :bigint           not null, primary key
#  sale_id      :bigint           not null
#  sales_tag_id :bigint           not null
#
class SaleTagging < ApplicationRecord
  db_belongs_to :sale, inverse_of: :sale_taggings
  db_belongs_to :sales_tag, inverse_of: :sale_taggings

  validates_db_uniqueness_of :sales_tag_id, scope: :sale_id
end
