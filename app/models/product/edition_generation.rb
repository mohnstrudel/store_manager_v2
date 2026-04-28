# frozen_string_literal: true

module Product::EditionGeneration
  extend ActiveSupport::Concern

  BASE_EDITION_ATTRIBUTES = {size_id: nil, version_id: nil, color_id: nil}.freeze

  included do
    before_validation :build_base_edition
  end

  def build_new_editions
    build_base_edition
    return unless sizes.any? || versions.any? || colors.any?

    editions.build(missing_edition_attributes)
  end

  def build_base_edition(sku: nil)
    edition = base_edition || editions.build(BASE_EDITION_ATTRIBUTES)
    fill_edition_sku(edition, sku)
    edition
  end

  def base_edition
    edition_from_memory = association(:editions).target.find { |ed| base_edition?(ed) }
    edition_from_memory || editions.find_by(BASE_EDITION_ATTRIBUTES)
  end

  def fill_edition_sku(edition, seed)
    return if edition.sku.present?

    edition.sku = seed.presence || default_base_sku
  end

  def default_base_sku
    return "product-#{id}-base" if id.present?

    "#{title.to_s.parameterize.presence || "product"}-base-#{SecureRandom.hex(4)}"
  end

  def base_edition?(edition)
    edition.size_id.nil? && edition.version_id.nil? && edition.color_id.nil?
  end

  def fetch_editions_with_title
    editions.includes(:version, :color, :size).select { |edition| edition.title.present? }
  end

  private

  def missing_edition_attributes
    attributes = []
    size_options.each do |size|
      version_options.each do |version|
        color_options.each do |color|
          edition_attributes = {
            size_id: size&.id,
            version_id: version&.id,
            color_id: color&.id,
            sku: combination_sku(size:, version:, color:)
          }.compact_blank

          next if editions.exists?(edition_attributes.except(:sku))

          attributes << edition_attributes
        end
      end
    end
    attributes
  end

  def combination_sku(size:, version:, color:)
    dimensions = [size&.id, version&.id, color&.id].compact
    return "#{title.to_s.parameterize.presence || "product"}-edition" if dimensions.blank?

    "#{title.to_s.parameterize.presence || "product"}-#{dimensions.join("-")}"
  end

  def skip_single_size?
    sizes.count == 1 && (versions.any? || colors.any?)
  end

  def size_options = skip_single_size? ? [nil] : sizes.presence || [nil]
  def version_options = versions.presence || [nil]
  def color_options = colors.presence || [nil]
end
