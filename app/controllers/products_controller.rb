# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :set_product, only: %i[show destroy]
  before_action :set_product_for_edit, only: %i[edit update]

  def index
    @products = Product.listed.search_by(params[:q]).page(params[:page])

    return unless stale?(etag: [@products, request.inertia?], last_modified: @products.maximum(:updated_at))

    render inertia: "Products/Index", props: {
      products: @products.map { |product| helpers.index_product_props(product) },
      pagination: helpers.pagination_props(@products),
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
      product: helpers.show_product_props(@product, can_pull_from_shopify: policy(@product).pull_from_shopify?),
      variants: @product.variants.map { |variant| helpers.variant_props(variant, variants_sales_sums, variants_purchases_sums) },
      active_sales: active_sales.map { |sale_item| helpers.product_sale_item_props(sale_item, @product) },
      completed_sales: complete_sales.map { |sale_item| helpers.product_sale_item_props(sale_item, @product) },
      purchases: purchases.map { |purchase| helpers.purchase_props(purchase) }
    }
  end

  def new
    @product = Product.new
    @product.build_base_variant

    render inertia: "Products/New", props: helpers.product_form_props(@product).merge(
      purchase: helpers.default_purchase_props
    )
  end

  def edit
    @product.build_base_variant

    render inertia: "Products/Edit", props: helpers.product_form_props(@product)
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
    redirect_to new_product_path, inertia: inertia_errors(@product.errors)
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
    redirect_to edit_product_path(@product), inertia: inertia_errors(@product.errors)
  end

  def destroy
    @product.destroy
    redirect_to products_url, notice: "Product was successfully destroyed", status: :see_other
  end

  private

  def set_product
    @product = Product.for_details.friendly.find(params.expect(:id))
  end

  def set_product_for_edit
    @product = Product.for_edit.friendly.find(params.expect(:id))
  end

  def extract_media_attributes
    raw = params[:media]
    return [] if raw.blank?

    raw_values = raw.is_a?(Array) ? raw : raw.values
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
end
