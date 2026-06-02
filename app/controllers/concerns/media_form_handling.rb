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

    raw_values = media_params.is_a?(Array) ? media_params : media_params.to_h.values
    raw_values.map do |attrs|
      attrs = attrs.is_a?(ActionController::Parameters) ? attrs.to_unsafe_h.with_indifferent_access : attrs.with_indifferent_access

      {
        id: attrs[:id].presence,
        alt: attrs[:alt],
        position: attrs[:position],
        _destroy: attrs[:_destroy],
        image: attrs[:image_blob_id].presence || attrs[:image]
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
        :image,
        :image_blob_id
      ]],
      new_images: []
    ) || ActionController::Parameters.new
    permitted.slice(:media, :new_images)
  end
end
