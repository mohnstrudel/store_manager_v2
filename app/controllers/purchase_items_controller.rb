# frozen_string_literal: true

class PurchaseItemsController < ApplicationController
  include MediaFormHandling

  before_action :set_purchase_item_for_show, only: :show
  before_action :set_purchase_item, only: %i[edit update destroy]

  def index
    @purchase_items = PurchaseItem
      .ordered_by_updated_date
      .includes(:warehouse, :shipping_company, purchase: [:supplier, :variant, :product], sale: :customer)
      .page(params[:page])
    @purchase_items = @purchase_items.search(params[:q]) if params[:q].present?

    return unless stale?(etag: [@purchase_items, request.inertia?], last_modified: @purchase_items.maximum(:updated_at))

    render inertia: "PurchaseItems/Index", props: {
      purchase_items: @purchase_items.map { |purchase_item| helpers.purchase_item_index_props(purchase_item) },
      pagination: helpers.pagination_props(@purchase_items),
      search: {q: params[:q].to_s}
    }
  end

  def show
    render inertia: "PurchaseItems/Show", props: {
      purchase_item: helpers.purchase_item_show_props(@purchase_item)
    }
  end

  def edit
    redirect_to_sale_item = params[:redirect_to_sale_item].present?
    render inertia: "PurchaseItems/Edit",
      props: helpers.purchase_item_edit_props(@purchase_item, redirect_to_sale_item:)
  end

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

  def destroy
    warehouse = @purchase_item.warehouse
    @purchase_item.destroy!

    redirect_to warehouse,
      notice: "Purchase item was successfully destroyed",
      status: :see_other
  end

  private

  def purchase_item_params
    params.expect(
      purchase_item: [:length,
        :width,
        :height,
        :weight,
        :shipping_cost,
        :tracking_number,
        :warehouse_id,
        :purchase_id,
        :redirect_to_sale_item,
        :shipping_company_id]
    )
  end

  def set_purchase_item_for_show
    @purchase_item = PurchaseItem.for_show.find(params.expect(:id))
  end

  def set_purchase_item
    @purchase_item = PurchaseItem.with_media.find(params.expect(:id))
  end
end
