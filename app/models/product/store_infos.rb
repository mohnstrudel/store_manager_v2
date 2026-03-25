# frozen_string_literal: true

module Product::StoreInfos
  extend ActiveSupport::Concern

  def apply_store_infos_attributes!(rows)
    return if rows.blank?

    rows.each do |attributes|
      apply_store_info_attributes!(attributes)
    end
  end

  private

  def apply_store_info_attributes!(attributes)
    if attributes[:id].blank?
      store_infos.create!(persisted_store_info_attributes(attributes))
      return
    end

    store_info = store_infos.find(attributes[:id])

    if attributes[:destroy]
      store_info.destroy!
      return
    end

    store_info.assign_attributes(persisted_store_info_attributes(attributes))
    store_info.save!
  end

  def persisted_store_info_attributes(attributes)
    attributes.except(:id, :destroy)
  end
end
