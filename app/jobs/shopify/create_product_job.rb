class Shopify::CreateProductJob < ApplicationJob
  def perform(product_id)
    product = Product.find(product_id)
    serialized_product = Shopify::ProductSerializer.serialize(product)

    if serialized_product.present?
      api_client = Shopify::ApiClient.new

      product_shopify_info = product.store_infos.find_or_initialize_by(store_name: :shopify)

      product_response = api_client.create_product(serialized_product)
      shopify_product_id = product_response["id"]

      product_shopify_info.assign_attributes(
        push_time: Time.current,
        store_id: shopify_product_id,
        slug: product_response["handle"]
      )
      product_shopify_info.save!

      if product.sizes.any? || product.versions.any? || product.colors.any?
        Shopify::CreateOptionsAndVariantsJob.perform_later(product.id, shopify_product_id)
      end

      true
    end
  end
end
