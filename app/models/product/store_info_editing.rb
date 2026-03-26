# frozen_string_literal: true

module Product::StoreInfoEditing
  extend ActiveSupport::Concern

  def apply_store_info_attributes!(rows)
    return if rows.blank?

    rows.each do |attributes|
      apply_single_store_info_attributes!(attributes)
    end

    reset_store_info_associations
  end

  private

  def apply_single_store_info_attributes!(attributes)
    if attributes[:id].blank?
      StoreInfo.create!(persisted_store_info_attributes(attributes).merge(storable: self))
      return
    end

    store_info = StoreInfo.find_by!(id: attributes[:id], storable: self)

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

  def reset_store_info_associations
    association(:store_infos).reset if association(:store_infos).loaded?
    association(:shopify_info).reset if association(:shopify_info).loaded?
    association(:woo_info).reset if association(:woo_info).loaded?
  end
end
