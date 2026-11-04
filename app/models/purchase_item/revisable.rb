# frozen_string_literal: true

module PurchaseItem::Revisable
  extend ActiveSupport::Concern

  def record(attributes, new_media_images:)
    transaction do
      assign_attributes(attributes)
      save!
      add_media(new_media_images)
    end
  end

  def revise(attributes:, media_attributes:, new_media_images:)
    transaction do
      update!(attributes)
      update_media(media_attributes)
      add_media(new_media_images)
    end
  end
end
