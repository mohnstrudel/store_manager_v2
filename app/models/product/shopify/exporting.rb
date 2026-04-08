# frozen_string_literal: true

module Product::Shopify::Exporting
  def shopify_payload
    {
      title: shopify_title,
      descriptionHtml: shopify_description_html,
      tags: shopify_tags
    }.compact
  end

  private

  def shopify_title
    "#{franchise.title} - #{title} | Resin #{shape.title} | by #{shopify_brand_titles}"
  end

  def shopify_description_html
    return nil if description.body.blank?

    description.body.to_html.strip
  end

  def shopify_tags
    shopify_info&.tag_list || []
  end

  def shopify_brand_titles
    titles = if brands.loaded?
      brands.map(&:title)
    else
      brands.pluck(:title)
    end

    titles.compact_blank.join(", ")
  end
end
