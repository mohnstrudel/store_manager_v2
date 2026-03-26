# frozen_string_literal: true

module Product::EditionGeneration
  extend ActiveSupport::Concern

  def build_new_editions
    return create_base_model_edition if base_model_case?
    return unless sizes.any? || versions.any? || colors.any?

    editions.build(build_edition_attributes)
  end

  def fetch_editions_with_title
    editions.includes(:version, :color, :size).select { |edition| edition.title.present? }
  end

  private

  def base_model_case?
    sizes.count == 1 && colors.empty? && versions.empty?
  end

  def create_base_model_edition
    attributes = {product_id: id}

    return if editions.exists?(attributes)

    editions.build(attributes)
  end

  def build_edition_attributes
    edition_attributes = []

    size_options.each do |size|
      version_options.each do |version|
        color_options.each do |color|
          attributes = {
            product_id: id,
            size_id: size&.id,
            version_id: version&.id,
            color_id: color&.id
          }.compact_blank

          next if editions.exists?(attributes)

          edition_attributes << attributes
        end
      end
    end

    edition_attributes
  end

  def size_options
    return [nil] if skip_single_size?
    return sizes if sizes.any?

    [nil]
  end

  def version_options
    versions.any? ? versions : [nil]
  end

  def color_options
    colors.any? ? colors : [nil]
  end

  def skip_single_size?
    sizes.count == 1 && (versions.any? || colors.any?)
  end
end
