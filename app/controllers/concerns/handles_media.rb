# frozen_string_literal: true

module HandlesMedia
  extend ActiveSupport::Concern

  private

  def handle_new_images_for(resource)
    new_images = media_params_for(resource)[:new_images]
    return unless new_images&.any?

    base_position = resource.media.maximum(:position) || 0

    new_images.each_with_index do |image, index|
      next unless image.respond_to?(:content_type) && image.content_type.start_with?("image/")
      resource.media.create!(
        image: image,
        position: base_position + index + 1
      )
    end
  end

  def handle_media_for(resource)
    media_params = media_params_for(resource)[:media]
    return unless media_params

    media_params = media_params.to_h.values
    return if media_params.empty?

    media_params.each do |attrs|
      next if attrs[:id].blank?

      media = resource.media.find(attrs[:id])

      if attrs[:_destroy].to_s == "1"
        media.destroy!
        next
      end

      if attrs[:image].respond_to?(:content_type)
        media.image.attach(attrs[:image])
      end

      updates = {}
      updates[:position] = attrs[:position] if attrs.key?(:position)
      updates[:alt] = attrs[:alt] if attrs.key?(:alt)
      media.update!(updates) if updates.any?
    end
  end

  def media_params_for(resource)
    param_key = resource.class.model_name.param_key.to_sym
    permitted = params.expect(param_key => [media: [[
      :id,
      :alt,
      :position,
      :_destroy,
      :image
    ]], new_images: []])
    permitted.slice(:media, :new_images)
  end
end
