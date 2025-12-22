module HandlesMedia
  extend ActiveSupport::Concern

  private

  def handle_new_images_for(resource)
    new_images = params.dig(param_name_for(resource), :new_images)
    return unless new_images&.any?

    base_position = resource.media.maximum(:position) || 0

    new_images.each_with_index do |image, index|
      next unless image.respond_to?(:content_type) && image.content_type.start_with?("image/")
      resource.media.create!(
        image: image,
        position: base_position + index
      )
    end
  end

  def param_name_for(resource)
    resource.class.model_name.param_key.to_sym
  end
end
