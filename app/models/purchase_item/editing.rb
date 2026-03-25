# frozen_string_literal: true

module PurchaseItem::Editing
  extend ActiveSupport::Concern

  def create_from_form!(attributes, new_media_images:)
    transaction do
      assign_attributes(attributes)
      save!
      add_new_media_from_form!(new_media_images)
    end
  end

  def apply_form_changes!(attributes:, media_attributes:, new_media_images:)
    transaction do
      update!(attributes)
      update_media_from_form!(media_attributes)
      add_new_media_from_form!(new_media_images)
    end
  end
end
