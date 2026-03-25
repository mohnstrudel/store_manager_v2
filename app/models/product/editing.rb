# frozen_string_literal: true

module Product::Editing
  extend ActiveSupport::Concern

  def create_from_form!(editions_attributes:, store_infos_attributes:, purchase_attributes:, new_media_images:)
    transaction do
      sync_full_title
      save!
      add_new_media_from_form!(new_media_images)
      apply_initial_purchase!(purchase_attributes)
      apply_editions_attributes!(editions_attributes)
      apply_store_info_attributes!(store_infos_attributes)
    end
  end

  def apply_form_changes!(product_attributes:, editions_attributes:, store_infos_attributes:, media_attributes:, new_media_images:)
    transaction do
      apply_form_attributes(product_attributes)
      apply_editions_attributes!(editions_attributes)
      save!
      apply_store_info_attributes!(store_infos_attributes)
      update_media_from_form!(media_attributes)
      add_new_media_from_form!(new_media_images)
    end
  end

  private

  def apply_form_attributes(attributes)
    assign_attributes(attributes.merge(slug: nil))
    sync_full_title
  end
end
