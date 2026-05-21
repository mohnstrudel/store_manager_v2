# frozen_string_literal: true

module Media::FormHandling
  extend ActiveSupport::Concern

  def add_new_media_from_form!(new_images)
    return if new_images.blank?

    base_position = media.maximum(:position)&.next || 0

    new_images.each_with_index do |image, index|
      attachable = resolve_attachable(image)
      next unless attachable

      media.create!(
        image: attachable,
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

      attachable = resolve_attachable(attrs[:image])
      media_item.image.attach(attachable) if attachable

      updates = attrs.slice(:position, :alt)
        .compact_blank
        .transform_keys(&:to_sym)

      media_item.update!(updates) if updates.any?
    end
  end

  private

  def resolve_attachable(value)
    return value if image_like?(value)
    return nil unless value.is_a?(String) && value.present?

    ActiveStorage::Blob.find_signed(value)
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    nil
  end

  def image_like?(value)
    return false unless value.respond_to?(:content_type)

    value.content_type.start_with?("image/") ||
      value.respond_to?(:tempfile)
  end

  def truthy?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end
end
