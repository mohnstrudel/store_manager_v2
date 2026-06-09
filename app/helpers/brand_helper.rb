# frozen_string_literal: true

module BrandHelper
  def brand_form_props(brand)
    {
      brand: brand_props(brand)
    }
  end

  def brand_props(brand)
    {
      id: brand.id,
      title: brand.title.to_s,
      created_at: formatted_timestamp(brand.created_at),
      updated_at: formatted_timestamp(brand.updated_at)
    }
  end
end
