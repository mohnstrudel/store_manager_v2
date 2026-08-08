# frozen_string_literal: true

module HasPreviewImages
  extend ActiveSupport::Concern
  include Media::FormHandling

  included do
    has_many :media, -> { ordered }, as: :mediaable, dependent: :destroy, inverse_of: :mediaable, class_name: "Media"
  end

  def prev_image_id(img_id)
    (media.where(id: ...img_id).ordered.last || media.ordered.last).id
  end

  def next_image_id(img_id)
    (media.where("id > ?", img_id).ordered.first || media.ordered.first).id
  end
end
