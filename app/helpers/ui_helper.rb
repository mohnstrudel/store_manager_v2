# frozen_string_literal: true

module UiHelper
  def thumb_url(model)
    return if model.media.blank?

    first_media = model.media.min_by(&:position)
    return unless first_media&.image&.attached?

    url_for(first_media.image.representation(:thumb))
  end
end
