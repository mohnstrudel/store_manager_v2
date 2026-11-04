# frozen_string_literal: true

module Media::Gallery
  extend ActiveSupport::Concern

  def add_media!(images)
    return if images.blank?

    base_position = media.maximum(:position)&.next || 0

    images.each_with_index do |image, index|
      attachable = resolve_attachable(image)
      next unless attachable

      media.create!(
        image: attachable,
        position: base_position + index
      )
    end
  end

  def update_media!(media_attributes)
    return if media_attributes.blank?

    existing_media = media.where(id: media_attributes.filter_map { |attrs| attrs[:id].presence }).index_by { |item| item.id.to_s }

    media_attributes.each do |attrs|
      if attrs[:id].blank?
        insert_media!(attrs)
        next
      end

      media_item = existing_media[attrs[:id].to_s]
      next unless media_item

      if truthy?(attrs[:_destroy])
        media_item.destroy!
        existing_media.delete(attrs[:id].to_s)
        next
      end

      revise_media_item!(media_item, attrs)
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

  def insert_media!(attrs)
    attachable = resolve_attachable(attrs[:image])
    return unless attachable

    media.create!(
      image: attachable,
      position: attrs[:position].to_i,
      alt: attrs[:alt].to_s
    )
  end

  def truthy?(value)
    ActiveModel::Type::Boolean.new.cast(value)
  end

  def revise_media_item!(media_item, attrs)
    replace_media_image(media_item, attrs[:image])

    updates = attrs.slice(:position, :alt)
      .compact_blank
      .transform_keys(&:to_sym)

    media_item.update!(updates) if updates.any?
  end

  def replace_media_image(media_item, image)
    attachable = resolve_attachable(image)
    media_item.image.attach(attachable) if attachable
  end
end
