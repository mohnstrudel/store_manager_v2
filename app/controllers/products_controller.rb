# frozen_string_literal: true

class ProductsController < ApplicationController
  include MediaFormHandling
  include JobsStatusNotice

  before_action :set_product, only: %i[show edit update destroy pull_from_shopify] # DISABLED: publish_to_shopify, push_to_shopify

  # GET /products or /products.json
  def index
    @products = Product.listed.search_by(params[:q]).page(params[:page])
  end

  # GET /products/1 or /products/1.json
  def show
    @active_sales = @product.fetch_active_sale_items
    @complete_sales = @product.fetch_completed_sale_items
    @editions_sales_sums = @product.sum_editions_sale_items
    @editions_purchases_sums = @product.sum_editions_purchase_items
  end

  # GET /products/new
  def new
    @product = Product.new
    @product.purchases.build do |purchase|
      purchase.payments.build
    end
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products or /products.json
  def create
    @product = Product.new(normalized_product_attributes)

    respond_to do |format|
      @product.create_from_form!(
        editions_attributes: normalized_editions_attributes,
        purchase_attributes: normalized_purchase_attributes
      ) do |product|
        product.add_new_media_from_form!(media_new_images_for(product))
        # DISABLED: Auto-push to Shopify on product create - not needed for now, will re-enable later
        # Shopify::CreateProductJob.perform_later(product.id)
      end

      format.html { redirect_to @product, notice: "Product was successfully created" }
      format.json { render :show, status: :created, location: @product }
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      format.html { render :new, status: :unprocessable_content }
      format.json { render json: @product.errors, status: :unprocessable_content }
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    respond_to do |format|
      @product.apply_form_changes!(
        product_attributes: normalized_product_attributes,
        editions_attributes: normalized_editions_attributes,
        store_infos_attributes: normalized_store_infos_attributes
      ) do |product|
        product.update_media_from_form!(normalized_media_attributes_for(product))
        product.add_new_media_from_form!(media_new_images_for(product))
      end

      format.html { redirect_to product_url(@product), notice: "Product was successfully updated" }
      format.json { render :show, status: :ok, location: @product }
    rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
      reload_product_with_preserved_errors!
      reassign_edition_attributes!
      format.html { render :edit, status: :unprocessable_content }
      format.json { render json: @product.errors, status: :unprocessable_content }
    end
  end

  # DELETE /products/1 or /products/1.json
  def destroy
    @product.destroy

    respond_to do |format|
      format.html { redirect_to products_url, notice: "Product was successfully destroyed" }
      format.json { head :no_content }
    end
  end

  # DISABLED: Push to Shopify functionality - not needed for now, will re-enable later
  # def publish_to_shopify
  #   Shopify::CreateProductJob.perform_later(@product.id)
  #
  #   respond_to do |format|
  #     format.turbo_stream { flash.now[:notice] = "Product is being published to Shopify" }
  #     format.html { redirect_to products_path, notice: "Product is being published to Shopify" }
  #   end
  # end
  #
  # def push_to_shopify
  #   Shopify::UpdateProductJob.perform_later(@product.id)
  #
  #   respond_to do |format|
  #     format.turbo_stream { flash.now[:notice] = "Product updates are being pushed to Shopify" }
  #     format.html { redirect_to products_path, notice: "Product updates are being pushed to Shopify" }
  #   end
  # end

  def pull_from_shopify
    notice = if @product.shopify_info&.store_id&.present?
      Shopify::PullProductJob.perform_later(@product.shopify_info.store_id)
      "Product is being pulled from Shopify"
    else
      "Product has not been published to Shopify yet"
    end

    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = notice }
      format.html { redirect_to products_path, notice: }
    end
  end

  def pull
    Shopify::PullProductsJob.perform_later(limit: params[:limit]&.to_i)
    Config.update_shopify_products_sync_time
    set_jobs_status_notice!
    redirect_back_or_to(products_path)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.for_details.friendly.find(params[:id])
  end

  def product_params
    params.expect(product: [
      :title,
      :description,
      :franchise_id,
      :shape_id,
      :sku,
      :woo_id,
      :shopify_id,
      brand_ids: [],
      color_ids: [],
      size_ids: [],
      version_ids: [],
      purchases_attributes: [[
        :item_price,
        :amount,
        :supplier_id,
        :order_reference,
        :warehouse_id,
        payments_attributes: [:value]
      ]]
    ])
  end

  def store_infos_params
    return ActionController::Parameters.new if params[:store_infos].blank?

    params.expect(store_infos: [[
      :id,
      :tag_list,
      :store_name,
      :_destroy
    ]])
  end

  def editions_params
    return ActionController::Parameters.new if params[:editions].blank?

    params.expect(editions: [[
      :id,
      :sku,
      :size_id,
      :version_id,
      :color_id,
      :purchase_cost,
      :selling_price,
      :weight,
      :_destroy
    ]])
  end

  def purchase_params
    params.dig(:product, :purchases_attributes, "0")
  end

  def normalized_product_attributes
    product_params.to_h
  end

  def normalized_store_infos_attributes
    return [] if params[:store_infos].blank?

    store_infos_params.to_h.values.map do |attrs|
      attrs = attrs.with_indifferent_access

      {
        id: attrs[:id].presence,
        tag_list: attrs[:tag_list],
        store_name: attrs[:store_name],
        destroy: ActiveModel::Type::Boolean.new.cast(attrs[:_destroy])
      }.compact
    end
  end

  def normalized_editions_attributes
    return [] if params[:editions].blank?

    editions_params.to_h.values.map do |attrs|
      attrs = attrs.with_indifferent_access

      {
        id: attrs[:id].presence,
        sku: attrs[:sku],
        size_id: attrs[:size_id],
        version_id: attrs[:version_id],
        color_id: attrs[:color_id],
        purchase_cost: attrs[:purchase_cost],
        selling_price: attrs[:selling_price],
        weight: attrs[:weight],
        destroy: ActiveModel::Type::Boolean.new.cast(attrs[:_destroy])
      }.compact
    end
  end

  def normalized_purchase_attributes
    return {} if purchase_params.blank?

    attrs = purchase_params.with_indifferent_access
    payment_attrs = attrs[:payments_attributes]&.with_indifferent_access

    {
      warehouse_id: attrs[:warehouse_id].presence,
      payment_value: payment_attrs&.values&.first&.with_indifferent_access&.[](:value)&.presence
    }.compact
  end

  # When the transaction fails, @product's associations are stale and may be in an
  # inconsistent state. We need to reload from the database to get fresh data, but
  # we can't lose the validation errors that caused the failure—otherwise the user
  # won't see what went wrong.
  def reload_product_with_preserved_errors!
    errors = @product.errors.dup
    @product = Product.for_details.friendly.find(params[:id])
    @product.errors.copy!(errors)
  end

  # After reloading, all the user's unsaved form input would be lost, showing the
  # original database values instead. We manually reassign the submitted params so
  # the form displays what the user actually typed. For new editions that failed to
  # save, we build temporary objects so they still appear in the form for correction.
  def reassign_edition_attributes!
    return if editions_params.blank?

    editions_params.to_h.values.each_with_index do |attrs, index|
      id = attrs["id"]

      if id.present?
        edition = @product.editions.to_a.find { |e| e.id.to_s == id.to_s }
        edition&.assign_attributes(attrs.except("_destroy"))
      else
        temp_edition = @product.editions.build(attrs.except("_destroy"))
        temp_edition.instance_variable_set(:@_new_edition_index, index)
      end
    end
  end
end
