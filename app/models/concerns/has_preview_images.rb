# frozen_string_literal: true

module HasPreviewImages
  extend ActiveSupport::Concern
  include Media::FormHandling

  included do
    has_many :media, -> { ordered }, as: :mediaable, dependent: :destroy, inverse_of: :mediaable, class_name: "Media"

    # TODO: Remove after #99
    has_many_attached :images, dependent: :purge_later do |attachable|
      attachable.variant :preview,
        format: :webp,
        resize_to_limit: [800, 800],
        preprocessed: true
      attachable.variant :thumb,
        format: :webp,
        resize_to_limit: [300, 300],
        preprocessed: true
      attachable.variant :nano,
        format: :webp,
        resize_to_limit: [120, 120],
        preprocessed: true
    end
  end

  def prev_image_id(img_id)
    (media.where(id: ...img_id).ordered.last || media.ordered.last).id
  end

  def next_image_id(img_id)
    (media.where("id > ?", img_id).ordered.first || media.ordered.first).id
  end
end
