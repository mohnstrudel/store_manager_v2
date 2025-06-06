module HasPreviewImages
  extend ActiveSupport::Concern

  included do
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
end
