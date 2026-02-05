# frozen_string_literal: true

module HandlesMedia
  extend ActiveSupport::Concern

  private

  def add_new_media(record)
    new_images = media_params_for(record)[:new_images]
    return if new_images.blank?

    base_position = record.media.maximum(:position)&.next || 1

    new_images.each_with_index do |image, index|
      next unless image_like?(image)

      record.media.create!(
        image: image,
        position: base_position + index
      )
    end
  end

  def update_media(record)
    media_attrs = media_params_for(record)[:media]
    return if media_attrs.blank?

    media_attrs = media_attrs.to_h.values.compact_blank

    media_attrs.each do |attrs|
      next if attrs[:id].blank?

      media_item = record.media.find_by(id: attrs[:id])

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

  def media_params_for(record)
    param_key = record.class.model_name.param_key.to_sym
    permitted = params.expect(
      param_key => [
        media: [[
          :id,
          :alt,
          :position,
          :_destroy,
          :image
        ]],
        new_images: []
      ]
    )
    permitted.slice(:media, :new_images)
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
