module HasPreviewImages
  extend ActiveSupport::Concern

  included do
    has_many :media, as: :mediaable, dependent: :destroy, inverse_of: :mediaable, class_name: "Media"
    accepts_nested_attributes_for :media, allow_destroy: true, reject_if: :all_blank

    def prev_image_id(img_id)
      (media.where(id: ...img_id).ordered.last || media.ordered.last).id
    end

    def next_image_id(img_id)
      (media.where("id > ?", img_id).ordered.first || media.ordered.first).id
    end

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

  class_methods do
    def with_thumb_media
      includes(media: {image_attachment: :blob})
    end
  end
end
