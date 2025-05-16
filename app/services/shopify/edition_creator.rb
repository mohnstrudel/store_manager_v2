class Shopify::EditionCreator
  def initialize(product, parsed_variant)
    @product = product
    @parsed_variant = parsed_variant.with_indifferent_access
  end

  def update_or_create!
    raise ArgumentError, "Product must be present" if @product.blank?
    raise ArgumentError, "Variant must be present" if @parsed_variant[:options].blank?

    ActiveRecord::Base.transaction do
      edition_attrs = prepare_attrs!
      edition = find_or_initialize(edition_attrs)
      edition.save!
    end
  end

  private

  def prepare_attrs!
    return if @parsed_variant[:options].blank?

    attributes = {}

    @parsed_variant[:options].each do |option|
      case option[:name]
      when "Color"
        attributes[:color] = Color.find_or_create_by!(value: option[:value])
      when "Size", "Scale"
        attributes[:size] = Size.find_or_create_by!(value: option[:value])
      when "Version", "Edition", "Variante"
        attributes[:version] = Version.find_or_create_by!(value: option[:value])
      end
    end

    attributes
  end

  def find_or_initialize(attrs)
    return if attrs.blank?

    edition = Edition
      .where(
        product: @product,
        shopify_id: @parsed_variant[:id]
      )
      .or(Edition.where(
        product: @product,
        shopify_id: nil,
        **attrs
      ))
      .first_or_initialize

    edition.assign_attributes(shopify_id: @parsed_variant[:id], **attrs)

    edition
  end
end
