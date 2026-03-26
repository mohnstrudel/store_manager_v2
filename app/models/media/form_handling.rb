# frozen_string_literal: true

module Media::FormHandling
  extend ActiveSupport::Concern

  def add_new_media_from_form!(new_images)
    return if new_images.blank?

    base_position = media.maximum(:position)&.next || 0

    new_images.each_with_index do |image, index|
      next unless image_like?(image)

      media.create!(
        image: image,
        position: base_position + index
      )
    end
  end

  def update_media_from_form!(media_attributes)
    return if media_attributes.blank?

    media_attributes.each do |attrs|
      next if attrs[:id].blank?

      media_item = media.find_by(id: attrs[:id])
      next unless media_item

      if truthy?(attrs[:_destroy])
        media_item.destroy!
        next
      end

      media_item.image.attach(attrs[:image]) if image_like?(attrs[:image])

      updates = attrs.slice(:position, :alt)
        .compact_blank
        .transform_keys(&:to_sym)

      media_item.update!(updates) if updates.any?
    end
  end

  private

  def image_like?(value)
    return false unless value.respond_to?(:content_type)

    value.content_type.start_with?("image/") ||
      value.respond_to?(:tempfile)
  end

  def truthy?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
