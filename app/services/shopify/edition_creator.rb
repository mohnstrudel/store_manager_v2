class Shopify::EditionCreator
  def initialize(product, parsed_edition)
    raise ArgumentError, "Expected a Product" unless product.is_a?(Product)

    @product = product
    @parsed_edition = parsed_edition.with_indifferent_access
  end

  def update_or_create!
    return if @parsed_edition[:options].blank?

    edition_attrs = find_or_create_edition_attrs
    return if edition_attrs.blank?

    ActiveRecord::Base.transaction do
      @edition = find_or_initialize(edition_attrs)
      @edition.assign_attributes(
        shopify_id: @parsed_edition[:id],
        **edition_attrs
      )
      @edition.save!
    end

    @edition
  end

  private

  def find_or_create_edition_attrs
    attributes = {}

    @parsed_edition[:options].each do |option|
      case option[:name]
      when "Color"
        attributes[:color] = Color.find_or_create_by(value: option[:value])
      when "Size", "Scale"
        attributes[:size] = Size.find_or_create_by(value: option[:value])
      when "Version", "Edition", "Variante"
        attributes[:version] = Version.find_or_create_by(value: option[:value])
      end
    end

    attributes
  end

  def find_or_initialize(attrs)
    Edition
      .where(
        product_id: @product.id,
        shopify_id: @parsed_edition[:id]
      )
      .or(Edition.where(
        product_id: @product.id,
        shopify_id: nil,
        **attrs
      ))
      .first_or_initialize
  end
end
