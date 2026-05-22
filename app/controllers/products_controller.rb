# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]

  def index
    @products = Product.listed.search_by(params[:q]).page(params[:page])

    render inertia: "Products/Index", props: {
      products: @products.map { |p| index_product_props(p) },
      pagination: pagination_props(@products),
      search: {q: params[:q].to_s},
      last_sync_at: helpers.format_last_fetched_at(Config.shopify_products_sync_at)
    }
  end

  def show
    active_sales = @product.active_sale_items
    complete_sales = @product.completed_sale_items
    purchases = @product.purchases.includes(:supplier, :variant, purchase_items: :warehouse)
    variants_sales_sums = @product.variant_sales_sums
    variants_purchases_sums = @product.variant_purchase_sums

    render inertia: "Products/Show", props: {
      product: show_product_props(@product),
      variants: @product.variants.map { |v| variant_props(v, variants_sales_sums, variants_purchases_sums) },
      active_sales: active_sales.map { |s| sale_item_props(s, @product) },
      completed_sales: complete_sales.map { |s| sale_item_props(s, @product) },
      purchases: purchases.map { |p| purchase_props(p) }
    }
  end

  def new
    @product = Product.new
    @product.build_base_variant

    render inertia: "Products/New", props: form_props(@product).merge(
      purchase: default_purchase_props
    )
  end

  def edit
    @product.build_base_variant

    render inertia: "Products/Edit", props: form_props(@product)
  end

  def create
    payload = Product::Editing::Payload.new(params:)
    @product = Product.new

    @product.save_editing!(
      product_attributes: payload.product_attributes,
      variants_attributes: payload.variants_attributes,
      store_infos_attributes: payload.store_infos_attributes,
      purchase_attributes: payload.purchase_attributes,
      media_attributes: extract_media_attributes
    )

    redirect_to @product, notice: "Product was successfully created", status: :see_other
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    redirect_to new_product_path, inertia: {errors: @product.errors}
  end

  def update
    payload = Product::Editing::Payload.new(params:)

    @product.save_editing!(
      product_attributes: payload.product_attributes,
      variants_attributes: payload.variants_attributes,
      store_infos_attributes: payload.store_infos_attributes,
      media_attributes: extract_media_attributes
    )

    redirect_to product_url(@product), notice: "Product was successfully updated", status: :see_other
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    @product.reload
    redirect_to edit_product_path(@product), inertia: {errors: @product.errors}
  end

  def destroy
    @product.destroy
    redirect_to products_url, notice: "Product was successfully destroyed", status: :see_other
  end

  private

  def set_product
    @product = Product.for_details.friendly.find(params[:id])
  end

  def extract_media_attributes
    raw = params[:media]
    return [] if raw.blank?

    raw_values = raw.is_a?(Array) ? raw : raw.to_unsafe_h.values
    raw_values.filter_map do |attrs|
      attrs = attrs.to_unsafe_h.symbolize_keys
      next if attrs[:id].blank? && attrs[:image_blob_id].blank?

      {
        id: attrs[:id].presence,
        alt: attrs[:alt],
        position: attrs[:position],
        _destroy: attrs[:_destroy],
        image: attrs[:image_blob_id]
      }.compact
    end
  end

  def index_product_props(product)
    {
      id: product.id,
      title: product.title,
      full_title: product.full_title.to_s,
      path: product_path(product),
      edit_path: edit_product_path(product),
      thumb_url: image_url_for(product, :thumb),
      variants: product.variants.reject(&:base_model?).map { |v|
        {id: v.id, title: v.title}
      },
      woo_store_id: product.woo_info&.store_id.to_s,
      shopify_id_short: product.shopify_info&.id_short.to_s,
      new_purchase_path: new_purchase_path(product:)
    }
  end

  def show_product_props(product)
    {
      id: product.id,
      title: product.title.to_s,
      full_title: product.full_title.to_s,
      path: product_path(product),
      edit_path: edit_product_path(product),
      franchise: {id: product.franchise_id, title: product.franchise.title},
      brands: product.brands.map { |b| {id: b.id, title: b.title} },
      sizes: product.sizes.map { |s| {id: s.id, value: s.value} },
      versions: product.versions.map { |v| {id: v.id, value: v.value} },
      colors: product.colors.map { |c| {id: c.id, value: c.value} },
      shape: product.shape.to_s,
      description_html: product.description.body&.to_html.to_s,
      media: product.media.filter_map { |m| show_media_props(m) },
      shopify_info: shopify_info_props(product),
      woo_info: woo_info_props(product),
      created_at_columns: product_timestamp_columns_props(product, :created_at),
      updated_at_columns: product_timestamp_columns_props(product, :updated_at),
      shopify_linked: product.shopify_linked?,
      can_pull_from_shopify: policy(product).pull_from_shopify?,
      shopify_pull_path: product_shopify_pull_path(product),
      new_purchase_path: new_purchase_path(product:)
    }
  end

  def show_media_props(media)
    return unless media.image.attached?

    {
      id: media.id,
      alt: media.alt.to_s,
      position: media.position,
      preview_url: url_for(media.image.representation(:preview)),
      thumb_url: url_for(media.image.representation(:thumb))
    }
  end

  def product_timestamp_columns_props(product, attribute)
    helpers.product_timestamp_columns(product, attribute).map do |column|
      {
        key: column[:key],
        label: column[:label],
        value: helpers.format_date(column[:value]).to_s
      }
    end
  end

  def shopify_info_props(product)
    info = product.shopify_info
    return nil unless info

    {
      store_id: info.store_id.to_s,
      id_short: info.id_short.to_s,
      tag_list: info.tag_list,
      product_url: product.build_shopify_url
    }
  end

  def woo_info_props(product)
    info = product.woo_info
    return nil unless info

    {
      store_id: info.store_id.to_s,
      product_url: info.product_url
    }
  end

  def variant_props(variant, sales_sums, purchase_sums)
    {
      id: variant.id,
      title: variant.title,
      types_name: variant.types_name,
      weight: variant.weight.to_f,
      purchase_cost: variant.purchase_cost.to_f,
      selling_price: variant.selling_price.to_f,
      deactivated: variant.deactivated?,
      active_sales_count: sales_sums[variant.id].to_i,
      purchases_count: purchase_sums[variant.id].to_i,
      shopify_id_short: variant.shopify_info&.id_short.to_s,
      woo_store_id: variant.woo_info&.store_id.to_s
    }
  end

  def sale_item_props(sale_item, product)
    sale = sale_item.sale
    store_type, store_id = store_info_for_sale(sale)

    {
      id: sale_item.id,
      sale_path: sale_path(sale),
      store_type: store_type,
      store_id: store_id.to_s,
      customer_name: sale.customer.full_name,
      customer_email: sale.customer.email.to_s,
      country: sale.shipping_address&.country.to_s,
      date: helpers.format_date(sale.woo_created_at.presence || sale_item.created_at).to_s,
      variant_title: product.variants.any? ? sale_item.variant&.title : nil,
      price: helpers.format_money(sale_item.price).to_s,
      qty: sale_item.qty,
      status: sale.status.to_s,
      warehouse: sale_item.purchase_items.first&.warehouse&.name.to_s,
      purchase_item_path: sale_item.purchase_items.first ? purchase_item_path(sale_item.purchase_items.first) : nil
    }
  end

  def store_info_for_sale(sale)
    if sale.shopify_info&.store_id.present?
      ["shopify", sale.shopify_info.id_short]
    elsif sale.woo_info&.store_id.present?
      ["woo", sale.woo_info.store_id]
    else
      [nil, sale.shopify_name.presence || sale.woo_store_id]
    end
  end

  def purchase_props(purchase)
    {
      id: purchase.id,
      path: purchase_path(purchase),
      supplier: purchase.supplier.title,
      order_reference: purchase.order_reference.to_s,
      variant_title: purchase.variant&.title,
      item_price: helpers.format_money(purchase.item_price).to_s,
      amount: purchase.amount,
      created_at: helpers.format_date(purchase.created_at).to_s,
      warehouses: purchase.purchase_items.map { |pi|
        {id: pi.id, name: pi.warehouse&.name.to_s}
      }
    }
  end

  def form_props(product)
    {
      product: form_product_props(product),
      options: form_options_props
    }
  end

  def form_product_props(product)
    {
      id: product.id,
      title: product.title.to_s,
      description_html: product.description.body&.to_html.to_s,
      franchise_id: product.franchise_id,
      shape: product.shape.to_s,
      brand_ids: product.brand_ids,
      path: product.persisted? ? product_path(product) : "",
      variants: product.variants.map { |v| form_variant_props(v) },
      store_infos: product.store_infos.map { |si| form_store_info_props(si) },
      media: product.media.filter_map { |m| show_media_props(m) }
    }
  end

  def form_variant_props(variant)
    {
      id: variant.id,
      sku: variant.sku.to_s,
      size_id: variant.size_id,
      version_id: variant.version_id,
      color_id: variant.color_id,
      purchase_cost: variant.purchase_cost.to_s,
      selling_price: variant.selling_price.to_s,
      weight: variant.weight.to_s,
      deactivated: variant.deactivated?,
      has_sales_or_purchases: variant.persisted? ? variant.has_sales_or_purchases? : false,
      _destroy: false
    }
  end

  def form_store_info_props(store_info)
    {
      id: store_info.id,
      store_name: store_info.store_name,
      tag_list: store_info.tag_list.join(", "),
      _destroy: false
    }
  end

  def form_options_props
    {
      franchises: Franchise.order(:title).map { |f| select_option(f.id, f.title) },
      brands: Brand.order(:title).map { |b| select_option(b.id, b.title) },
      shapes: Product.shape_options,
      sizes: Size.order(:value).map { |s| select_option(s.id, s.value) },
      versions: Version.order(:value).map { |v| select_option(v.id, v.value) },
      colors: Color.order(:value).map { |c| select_option(c.id, c.value) },
      suppliers: Supplier.order(:title).map { |s| select_option(s.id, s.title) },
      warehouses: Warehouse.order(:name).map { |w| select_option(w.id, w.name) },
      store_names: StoreInfo.assignable_store_names
    }
  end

  def select_option(value, label)
    {value:, label:}
  end

  def default_purchase_props
    default_warehouse = Warehouse.find_by(is_default: true)
    {
      supplier_id: nil,
      order_reference: "",
      item_price: "",
      amount: "",
      warehouse_id: default_warehouse&.id,
      payment_value: ""
    }
  end

  def image_url_for(product, variant_name)
    return unless product.media.any?

    first = product.media.min_by(&:position)
    return unless first&.image&.attached?

    url_for(first.image.representation(variant_name))
  rescue StandardError
    nil
  end

end
