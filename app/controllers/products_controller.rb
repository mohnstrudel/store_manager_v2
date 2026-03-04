# frozen_string_literal: true

class ProductsController < ApplicationController
  include ActionView::Helpers::OutputSafetyHelper
  include HandlesMedia

  before_action :set_product, only: %i[show edit update destroy publish_to_shopify push_to_shopify pull_from_shopify]

  # GET /products or /products.json
  def index
    @products = Product.includes_index_associations.listed.search_by(params[:q]).page(params[:page])
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
    @product = Product.new(product_params)

    respond_to do |format|
      ActiveRecord::Base.transaction do
        @product.save!
        add_new_media(@product)
        handle_new_purchase if purchase_params.present?
        create_or_update_product_editions!
        Shopify::CreateProductJob.perform_later(@product.id)
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
    @product.assign_attributes(product_params.to_h.merge(slug: nil))
    @product.assign_attributes(full_title: Product.generate_full_title(@product))

    respond_to do |format|
      ActiveRecord::Base.transaction do
        create_or_update_product_editions!
        @product.save!
        create_or_update_product_store_infos!
        update_media(@product)
        add_new_media(@product)
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

  def publish_to_shopify
    Shopify::CreateProductJob.perform_later(@product.id)

    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "Product is being published to Shopify" }
      format.html { redirect_to products_path, notice: "Product is being published to Shopify" }
    end
  end

  def push_to_shopify
    Shopify::UpdateProductJob.perform_later(@product.id)

    respond_to do |format|
      format.turbo_stream { flash.now[:notice] = "Product updates are being pushed to Shopify" }
      format.html { redirect_to products_path, notice: "Product updates are being pushed to Shopify" }
    end
  end

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
    limit = params[:limit]&.to_i

    Shopify::PullProductsJob.perform_later(limit:)
    Config.update_shopify_products_sync_time

    statuses_link = view_context.link_to(
      "jobs statuses dashboard", root_url + "jobs/statuses", class: "link"
    )

    flash[:notice] = safe_join([
      "Success! Visit ",
      statuses_link,
      " to track synchronization progress"
    ])

    redirect_back_or_to(products_path)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_product
    @product = Product.includes_show_associations.friendly.find(params[:id])
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

  def handle_new_purchase
    return unless (purchase = @product.purchases.last)

    warehouse_id = purchase_params[:warehouse_id]
    payment_value = purchase_params[:payments_attributes]&.values&.first&.[](:value)

    if warehouse_id
      purchase.add_items_to_warehouse(warehouse_id)
      purchase.link_with_sales
    end

    purchase.payments.create(value: payment_value) if payment_value
  end

  def create_or_update_product_store_infos!
    return if store_infos_params.blank?

    store_infos_params.to_h.values.each do |attrs|
      id = attrs.delete("id")
      should_destroy = attrs.delete("_destroy") == "1"

      if id.blank?
        @product.store_infos.create!(attrs)
        next
      end

      if should_destroy
        @product.store_infos.find(id).destroy
        next
      end

      store_info = @product.store_infos.find(id)
      store_info.assign_attributes(attrs)
      store_info.save!
    end
  end

  def create_or_update_product_editions!
    return if editions_params.blank?

    new_editions, existing_editions =
      editions_params.to_h.values.partition do |edt_params|
        edt_params["id"].blank?
      end

    new_editions.each do |attrs|
      validate_edition_combination!(attrs)
      @product.editions.create!(attrs)
    end

    existing_editions.each do |attrs|
      id = attrs.delete("id")
      should_destroy = attrs.delete("_destroy") == "1"
      edition = @product.editions.find(id)

      if should_destroy
        handle_edition_destruction(edition)
      else
        # Assign attributes first so sku_changed? works correctly
        edition.assign_attributes(attrs)
        validate_edition_sku_uniqueness!(edition)
        edition.save!
      end
    end
  end

  def validate_edition_sku_uniqueness!(edition)
    return unless edition.sku_changed?

    existing_edition = Edition.where.not(id: edition.id).find_by(sku: edition.sku)

    if existing_edition
      @product.errors.add(:editions, "#{edition.title} sku: has already been taken")
      raise ActiveRecord::RecordInvalid.new(@product)
    end
  end

  def validate_edition_combination!(attrs)
    combination = {
      size_id: attrs["size_id"],
      version_id: attrs["version_id"],
      color_id: attrs["color_id"]
    }.compact_blank

    duplicate = @product.editions.find_by(combination)
    return unless duplicate

    @product.errors.add(:editions, "Combination #{duplicate.title} already exists")
    raise ActiveRecord::RecordInvalid.new(@product)
  end

  def handle_edition_destruction(edition)
    if edition.has_sales_or_purchases?
      edition.update!(deactivated_at: Time.current)
    else
      edition.destroy!
    end
  end

  # When the transaction fails, @product's associations are stale and may be in an
  # inconsistent state. We need to reload from the database to get fresh data, but
  # we can't lose the validation errors that caused the failure—otherwise the user
  # won't see what went wrong.
  def reload_product_with_preserved_errors!
    errors = @product.errors.dup
    @product = Product.includes_show_associations.friendly.find(params[:id])
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
