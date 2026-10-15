# frozen_string_literal: true

# == Schema Information
#
# Table name: variant_import_conflicts
#
#  id                     :bigint           not null, primary key
#  options                :jsonb            not null
#  sku                    :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  conflicting_variant_id :bigint
#  product_id             :bigint           not null
#  store_id               :string           not null
#
class VariantImportConflict < ApplicationRecord
  db_belongs_to :product
  belongs_to :conflicting_variant, class_name: "Variant", optional: true

  validates :store_id, presence: true

  def self.record!(store_id:, **attributes)
    find_or_initialize_by(store_id:).update!(attributes)
  end

  def self.resolve!(store_id)
    where(store_id:).delete_all
  end

  def self.keep_only!(product, store_ids)
    where(product:).where.not(store_id: store_ids).delete_all
  end
end
