class SyncPurchasesJob < ApplicationJob
  queue_as :default

  include Sanitizable

  PRODUCTS_JOB = SyncWooProductsJob.new

  def perform(*)
    sync_purchases_from_file(*)
  end

  def sync_purchases_from_file(file = File.read("purchases.json"))
    invalid_purchases = []
    parsed_purchases = JSON.parse(file, symbolize_names: true)

    total = parsed_purchases.size
    progressbar = ProgressBar.create(
      title: self.class.name + " of #{total} purchases",
      total:
    )

    parsed_purchases.each do |parsed_purchase|
      progressbar.increment

      next if parsed_purchase[:canbeignored].present?

      invalid_purchases, has_erros = validate_keys(
        parsed_purchase,
        invalid_purchases
      )
      next if has_erros

      product = find_or_create_product(
        parsed_purchase[:wooid],
        parsed_purchase[:product]
      )
      variation = find_or_create_variation(
        product,
        parsed_purchase[:wooid],
        parsed_purchase[:variationid],
        parsed_purchase[:version]
      )

      if parsed_purchase[:sku]
        if variation
          variation.update(sku: parsed_purchase[:sku])
        else
          product.update(sku: parsed_purchase[:sku])
        end
      end

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
      :orderreference,
      :product,
      :itemprice,
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
    more_than_one_space_match = /\s{2,}/
    string
      .sub(resin_statue_match, "")
      .sub(deposit_match, "")
      .sub(copyright_match, "")
      .sub(more_than_one_space_match, " ")
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

  def find_or_create_product(parsed_woo_product_id, parsed_product)
    product_name = sanitize_product_name(parsed_product)
    woo_product_id = parsed_woo_product_id.to_i
    woo_product_id = nil if woo_product_id.to_s != parsed_woo_product_id

    product = if woo_product_id
      Product.find_by(woo_id: woo_product_id).presence ||
        PRODUCTS_JOB.get_product(woo_product_id)
    else
      brand_title = Brand.parse_brand(product_name)

      if brand_title
        product_name = product_name.sub(/#{brand_title}/i, "").strip
        brand = Brand.find_by("LOWER(title) LIKE ?", brand_title.downcase) ||
          Brand.create(title: brand_title)
        brand.products.find_or_create_by(scaffold_product(product_name))
      else
        Product.find_or_create_by(scaffold_product(product_name))
      end
    end

    parsed_size = Size.parse_size(product_name)

    if parsed_size
      product.sizes << Size.find_or_create_by(value: parsed_size)
    end

    product
  end

  def parse_versions(parsed_version)
    parsed_version = smart_titleize(sanitize(parsed_version))
    unknown_colors = ["Pink", "White", "Weiß", "Schwarz"]

    color = if parsed_version.in?(unknown_colors)
      Color.find_or_create_by(value: parsed_version)
    else
      Color.find_by(value: parsed_version)
    end

    size = Size.find_by(value: Size.sanitize_size(parsed_version))

    version = Version.find_by("LOWER(value) LIKE ?", parsed_version.downcase)

    [color, size, version]
  end

  def find_or_create_variation(
    product,
    woo_product_id,
    woo_variation_id,
    parsed_version
  )
    if woo_variation_id
      Variation.find_by(woo_id: woo_variation_id).presence ||
        (SyncWooVariationsJob.perform_now([woo_product_id]) &&
          Variation.find_by(woo_id: woo_variation_id))
    else
      return if parsed_version.blank?

      color, size, version = parse_versions(parsed_version)

      if {color:, size:, version:}.compact_blank.blank?
        Variation.find_or_create_by({
          product:,
          version: Version.create(value: parsed_version)
        })
      else
        Variation.find_or_create_by(
          {product:}.merge({color:, size:, version:}.compact_blank)
        )
      end
    end
  end
end
