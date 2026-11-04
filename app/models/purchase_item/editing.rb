# frozen_string_literal: true

module PurchaseItem::Editing
  extend ActiveSupport::Concern

  def create_with_media!(attributes, new_media_images:)
    transaction do
      assign_attributes(attributes)
      save!
      add_media!(new_media_images)
    end
  end

  def update_with_media!(attributes:, media_attributes:, new_media_images:)
    transaction do
      update!(attributes)
      update_media!(media_attributes)
      add_media!(new_media_images)
    end
  end
end
