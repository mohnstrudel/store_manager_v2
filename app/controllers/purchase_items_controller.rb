# frozen_string_literal: true

class PurchaseItemsController < ApplicationController
  include MediaFormHandling

  before_action :set_purchase_item, only: %i[show edit update destroy]

  # GET /warehouse_products
  def index
    @purchase_items = PurchaseItem
      .ordered_by_updated_date
      .includes(:warehouse, :shipping_company, purchase: [:supplier, :variant, :product], sale: :customer)
      .page(params[:page])
    @purchase_items = @purchase_items.search(params[:q]) if params[:q].present?

    render inertia: "PurchaseItems/Index", props: {
      purchase_items: @purchase_items.map { |purchase_item| helpers.purchase_item_index_props(purchase_item) },
      pagination: helpers.pagination_props(@purchase_items),
      search: {q: params[:q].to_s}
    }
  end

  # GET /purchase_items/1
  def show
    render inertia: "PurchaseItems/Show", props: {
      purchase_item: helpers.purchase_item_show_props(@purchase_item)
    }
  end

  # GET /purchase_items/1/edit
  def edit
    redirect_to_sale_item = params[:redirect_to_sale_item].present?
    render inertia: "PurchaseItems/Edit",
      props: helpers.purchase_item_edit_props(@purchase_item, redirect_to_sale_item:)
  end

  # PATCH/PUT /purchase_items/1
  def update
    @purchase_item.apply_form_changes!(
      attributes: purchase_item_params.except(:redirect_to_sale_item).to_h,
      media_attributes: normalized_media_attributes_for(@purchase_item),
      new_media_images: media_new_images_for(@purchase_item)
    )

    path = purchase_item_params[:redirect_to_sale_item] ?
      @purchase_item.sale_item :
      @purchase_item

    redirect_to path, notice: "Purchase item was successfully updated", status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to edit_purchase_item_path(@purchase_item), inertia: inertia_errors(@purchase_item.errors)
  end

  # DELETE /purchase_items/1
  def destroy
    warehouse = @purchase_item.warehouse
    @purchase_item.destroy!

    redirect_to warehouse,
      notice: "Purchase item was successfully destroyed",
      status: :see_other
  end

  private

  def set_purchase_item
    @purchase_item = PurchaseItem.with_media.find(params.expect(:id))
  end

  # Only allow a list of trusted parameters through.
  def purchase_item_params
    params.expect(
      purchase_item: [:length,
        :width,
        :height,
        :weight,
        :expenses,
        :shipping_cost,
        :tracking_number,
        :warehouse_id,
        :purchase_id,
        :sale_item_id,
        :redirect_to_sale_item,
        :shipping_company_id]
    )
  end
end
