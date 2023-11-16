class SyncWooProductsJob < ApplicationJob
  queue_as :default

  URL = "https://store.handsomecake.com/wp-json/wc/v3/products/"
  CONSUMER_KEY = Rails.application.credentials.dig(:woo_api, :user)
  CONSUMER_SECRET = Rails.application.credentials.dig(:woo_api, :pass)
  # We can find the published size in the store's dashboard
  SIZE = 1200
  PER_PAGE = 100

  def perform
    woo_products = get_woo_products
    parsed_woo_products = parse_woo_products(woo_products)
    save_woo_products_to_db(parsed_woo_products)
  end

  def save_woo_products_to_db(parsed_woo_products)
    parsed_woo_products.each do |woo_product|
      product = Product.new({
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
      product.save!
    end
  end

  def get_woo_products
    progressbar = ProgressBar.create(title: "SyncWooProductsJob")
    step = 100 / (SIZE / PER_PAGE)
    pages = (SIZE / PER_PAGE).ceil
    page = 1
    woo_products = []
    while page <= pages
      response = HTTParty.get(
        URL,
        query: {
          per_page: PER_PAGE,
          page: page,
          status: "publish"
        },
        basic_auth: {
          username: CONSUMER_KEY,
          password: CONSUMER_SECRET
        }
      )
      woo_products.concat(JSON.parse(response.body, symbolize_names: true))
      step.times {
        progressbar.increment
        sleep 0.5
      }
      page += 1
    end
    woo_products
  end

  def parse_woo_products(woo_products)
    parsed_woo_products = woo_products.map do |woo_product|
      next if woo_product[:attributes].blank?
      woo_name = sanitize(woo_product[:name])
      franchise = woo_name.include?(" - ") ? woo_name.split(" - ").first : woo_name.split(" | ").first
      title = woo_name.include?(" - ") ? woo_name.split(" | ").first.split(" - ").last : franchise
      shape = woo_name.match(/\b(bust|statue)\b/i)
      product = {
        woo_id: woo_product[:id],
        title: title,
        franchise: franchise,
        shape: shape.present? && shape[0]
      }
      options = woo_product[:attributes].map do |attr|
        attrs = {}
        if attr[:name] == "Version"
          attrs[:versions] = attr[:options].map(&method(:sanitize))
        end
        if attr[:name] == "Size" || attr[:name] == "Maßstab"
          attrs[:sizes] = attr[:options].map(&method(:sanitize))
        end
        if attr[:name] == "Color"
          attrs[:colors] = attr[:options].map(&method(:sanitize))
        end
        if attr[:name] == "Marke" || attr[:name] == "Brand"
          attrs[:brands] = attr[:options].map(&method(:sanitize))
        end
        attrs
      end
      product.merge(*options.compact.reject(&:empty?))
    end
    parsed_woo_products.compact.uniq { |el| el[:woo_id] }
  end

  private

  def sanitize(string)
    string.tr(" ", " ").gsub(/—|–/, "-").gsub("&amp;", "&").split("|").map { |s| s.strip }.join(" | ")
  end

  def save_file(data, file)
    file_path = Rails.root.join("#{file}.json")
    File.write(file_path, JSON.generate(data))
  end
end
