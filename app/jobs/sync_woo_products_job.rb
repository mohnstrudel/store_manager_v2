class SyncWooProductsJob < ApplicationJob
  queue_as :default

  URL = "https://store.handsomecake.com/wp-json/wc/v3/products/"
  CONSUMER_KEY = Rails.application.credentials.dig(:woo_api, :user)
  CONSUMER_SECRET = Rails.application.credentials.dig(:woo_api, :pass)
  # We can find the published size in the store's dashboard
  SIZE = 1108
  PER_PAGE = 100

  def perform(*args)
    save_woo_products_to_db
  end

  def save_woo_products_to_db
    woo_products = get_woo_products(method(:map_woo_products_to_model))
    woo_products.each do |woo_product|
      next if Product.find_by(woo_id: woo_product[:woo_id])
      product = Product.create({
        title: woo_product[:title],
        woo_id: woo_product[:woo_id],
        franchise: Franchise.find_or_create_by(title: woo_product[:franchise]),
        shape: Shape.find_or_create_by(title: woo_product[:shape])
      })
      woo_product[:brands]&.each do |i|
        product.brands << Brand.find_or_create_by(title: i)
      end
      woo_product[:sizes]&.each do |i|
        product.sizes << Size.find_or_create_by(value: i)
      end
      woo_product[:versions]&.each do |i|
        product.versions << Version.find_or_create_by(value: i)
      end
      woo_product[:colors]&.each do |i|
        product.colors << Color.find_or_create_by(value: i)
      end
    rescue => e
      Rails.logger.error "Full error: #{e}"
      Rails.logger.error "Error occurred at #{e.backtrace.first}"
    end
  end

  def get_woo_products(mapper, size = SIZE, per_page = PER_PAGE)
    pages = (size / per_page).ceil
    page = 1
    products = []
    while page <= pages
      response = HTTParty.get(
        URL,
        query: {
          per_page: per_page,
          page: page,
          status: "publish"
        },
        basic_auth: {
          username: CONSUMER_KEY,
          password: CONSUMER_SECRET
        }
      )
      woo_products = JSON.parse(response.body, symbolize_names: true)
      result = mapper.call(woo_products)
      products.concat(result)
      page += 1
    end
    products
  end

  def map_woo_products_to_model(woo_products)
    result = woo_products.map do |woo_product|
      next if woo_product[:attributes].blank?
      name = woo_product[:name].gsub("&amp;", "&")
      shape = name.match(/\b(bust|statue)\b/i)
      title = name.split(" - ")[0]
      franchise = name.split(" - ")[1] && name.split(" - ")[1].split(" | ")[0]
      product = {
        woo_id: woo_product[:id],
        title: title,
        franchise: franchise,
        shape: shape.present? && shape[0]
      }
      options = woo_product[:attributes].map do |attr|
        attrs = {}
        if attr[:name] == "Version"
          attrs[:versions] = attr[:options]
        end
        if attr[:name] == "Size" || attr[:name] == "Maßstab"
          attrs[:sizes] = attr[:options]
        end
        if attr[:name] == "Color"
          attrs[:colors] = attr[:options]
        end
        if attr[:name] == "Marke" || attr[:name] == "Brand"
          attrs[:brands] = attr[:options]
        end
        attrs
      end
      product.merge(*options.compact.reject(&:empty?))
    end
    result.compact
  end

  private

  # This method was used to get products with empty attributes.
  # In order to use it again, we need to put in the separate job.
  def get_empty_attrs_woo_products
    file_path = Rails.root.join("empty_woo_products.json")
    result = get_woo_products(method(:map_empty_attrs_products), SIZE)
    File.write(file_path, JSON.generate(result))
  end

  def map_empty_attrs_products(woo_products)
    result = woo_products.map do |woo_product|
      next if woo_product[:attributes].present?
      {
        id: woo_product[:id],
        name: woo_product[:name],
        permalink: woo_product[:permalink],
        admin_url: "https://store.handsomecake.com/wp-admin/post.php?post=#{woo_product[:id]}&action=edit"
      }
    end
    result.compact
  end
end
