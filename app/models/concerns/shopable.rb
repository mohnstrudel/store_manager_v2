module Shopable
  extend ActiveSupport::Concern

  included do
    def shop_id
      woo_id.presence || shopify_id_short.presence
    end

    def shopify_id_short
      class_name = self.class.class_name
      shopify_id&.gsub("gid://shopify/#{external_name_for(class_name)}/", "")
    end
  end

  def external_name_for(our_name)
    case our_name
    when "Sale"
      "Order"
    when "Edition"
      "ProductVariant"
    else
      our_name
    end
  end
end
