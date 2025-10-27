class Shopify::CreateProductJob < ApplicationJob
  def perform(product_id)
    product = Product.find(product_id)
    serialized_product = Shopify::ProductSerializer.serialize(product)

    if serialized_product.present?
      api_client = Shopify::ApiClient.new
      store_info = product.store_infos.find_or_initialize_by(name: :shopify)

      product_response = api_client.create_product(serialized_product)

      store_info.assign_attributes(
        push_time: Time.current,
        store_product_id: product_response["id"],
        slug: product_response["handle"]
      )
      store_info.save!
    end
  end
end
