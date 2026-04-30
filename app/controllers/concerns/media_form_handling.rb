# frozen_string_literal: true

module MediaFormHandling
  extend ActiveSupport::Concern

  private

  def media_new_images_for(record)
    media_form_params_for(record)[:new_images]
  end

  def normalized_media_attributes_for(record)
    media_params = media_form_params_for(record)[:media]
    return [] if media_params.blank?

    media_params.to_h.values.map do |attrs|
      attrs = attrs.with_indifferent_access

      {
        id: attrs[:id].presence,
        alt: attrs[:alt],
        position: attrs[:position],
        _destroy: attrs[:_destroy],
        image: attrs[:image]
      }.compact
    end
  end

  def media_form_params_for(record)
    param_key = record.class.model_name.param_key.to_sym
    media_params = params.dig(param_key)&.slice(:media, :new_images)
    permitted = media_params&.permit(
      media: [[
        :id,
        :alt,
        :position,
        :_destroy,
        :image
      ]],
      new_images: []
    ) || ActionController::Parameters.new
    permitted.slice(:media, :new_images)
  end
end
