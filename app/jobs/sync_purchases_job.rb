class SyncPurchasesJob < ApplicationJob
  queue_as :default

  include Sanitizable

  def perform(*)
    sync_purchases_from_file(*)
  end

  def sync_purchases_from_file(file = File.read("purchases.json"))
    invalid_purchases = []
    parsed_purchases = JSON.parse(file, symbolize_names: true)

    parsed_purchases.each do |parsed_purchase|
      next if parsed_purchase[:canbeignored].present?

      invalid_purchases, has_erros = validate_keys(
        parsed_purchase,
        invalid_purchases
      )
      next if has_erros

      synced = Base64.encode64(parsed_purchase.to_s).last(64)
      next if Purchase.find_by(synced:).present?

      product_name = sanitize_product_name(parsed_purchase[:product])
      brand_title = Brand.parse_brand(product_name)

      product = if brand_title
        product_name = product_name.sub(/#{brand_title}/i, "").strip
        brand = Brand.find_or_create_by(title: brand_title)
        brand.products.find_or_create_by(scaffold_product(product_name))
      else
        Product.find_or_create_by(scaffold_product(product_name))
      end

      parsed_size = Size.parse_size(product_name)
      if parsed_size
        product.sizes.find_or_create_by(value: parsed_size)
      end

      if parsed_purchase[:version]
        color, size, version = parse_versions(parsed_purchase[:version])
        variation = if {color:, size:, version:}.compact_blank.blank?
          Variation.find_or_create_by({
            product:,
            version: Version.create(value: parsed_purchase[:version])
          })
        else
          Variation.find_or_create_by(
            {product:}.merge({color:, size:, version:}.compact_blank)
          )
        end
      end

      full_title = Product.generate_full_title(
        product,
        product&.brands,
        size&.value,
        version&.value,
        color&.value
      )

      purchase_date = if parsed_purchase[:purchasedate]
        Date.parse(parsed_purchase[:purchasedate])
      else
        Time.zone.today
      end

      purchase = Purchase.new({
        amount: parsed_purchase[:amount],
        order_reference: parsed_purchase[:orderreference],
        item_price: parsed_purchase[:itemprice],
        supplier: Supplier.find_or_create_by(title: parsed_purchase[:supplier]),
        full_title:,
        purchase_date:,
        product:,
        variation:
      })

      payments = parsed_purchase.select { |key, _|
        key.to_s.include?("paymentvalue")
      }
      payments.each do |key, value|
        date = parsed_purchase[:"paymentdate#{key[-1]}"]
        payment_date = if date.present?
          Date.parse(date)
        else
          Time.zone.today
        end
        purchase.payments.build({
          value: value * parsed_purchase[:amount],
          payment_date:
        })
      end

      purchase.save!
    end

    if invalid_purchases.any?
      Dir.mkdir("__debug") unless Dir.exist?("__debug")
      File.write(
        "__debug/sync-purchase-errors.json",
        JSON.pretty_generate(invalid_purchases)
      )
    end
  end

  def validate_keys(parsed_purchase, errors)
    ititial_size = errors.size
    required_keys = [
      :amount,
      :supplier,
      :itemprice,
      :orderreference,
      :product,
      :purchasedate
    ]
    empty_keys = required_keys.select { |key| parsed_purchase[key].blank? }
    if empty_keys.any?
      errors.push({empty_keys:, parsed_purchase:})
    end
    [errors, errors.size != ititial_size]
  end

  def sanitize_product_name(string)
    resin_statue_match = /Resin Statue/i
    deposit_match = /Deposit/i
    copyright_match = /（Copyright）/i
    string
      .sub(resin_statue_match, "")
      .sub(deposit_match, "")
      .sub(copyright_match, "")
      .strip
  end

  def scaffold_product(product_name)
    product_job = SyncWooProductsJob.new
    title, franchise_title, shape_title = product_job
      .parse_product_name(product_name)
    {
      title:,
      franchise: Franchise.find_or_create_by(title: franchise_title),
      shape: Shape.find_or_create_by(title: shape_title)
    }
  end

  def parse_versions(parsed_version)
    parsed_version = smart_titleize(sanitize(parsed_version))
    unknown_colors = ["Pink", "White", "Weiß", "Schwarz"]

    color = if parsed_version.in?(unknown_colors)
      Color.find_or_create_by(value: parsed_version)
    else
      Color.find_by(value: parsed_version)
    end

    variation_size = Size.parse_size(parsed_version)
    if variation_size
      size = Size.find_by(value: variation_size)
    end

    version = Version.find_by("LOWER(value) LIKE ?", parsed_version.downcase)

    [color, size, version]
  end
end
