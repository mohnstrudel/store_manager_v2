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
      purchase_items: @purchase_items.map { |purchase_item| purchase_item_index_props(purchase_item) },
      pagination: pagination_props(@purchase_items),
      search: {q: params[:q].to_s}
    }
  end

  # GET /purchase_items/1
  def show
    render inertia: "PurchaseItems/Show", props: {
      purchase_item: purchase_item_show_props(@purchase_item)
    }
  end

  # GET /purchase_items/1/edit
  def edit
    prepare_edit_form
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
    prepare_edit_form
    render :edit, status: :unprocessable_content
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
    @purchase_item = PurchaseItem.with_media.find(params[:id])
  end

  def prepare_edit_form
    @sale_items = SaleItem.for_edit_linking(@purchase_item)
    prepare_form_options
  end

  def prepare_form_options
    @purchases = Purchase.for_form_select
    @shipping_companies = ShippingCompany.order(:name)
    @warehouse_options = Warehouse.order(:name)
  end

  def purchase_item_show_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      edit_path: edit_purchase_item_path(purchase_item),
      destroy_path: purchase_item_path(purchase_item),
      purchase_path: purchase_path(purchase_item.purchase),
      purchase_title: purchase_item.purchase.full_title.to_s,
      sale_path: purchase_item.sale ? sale_path(purchase_item.sale) : nil,
      sale_item_path: purchase_item.sale_item ? sale_item_path(purchase_item.sale, purchase_item.sale_item) : nil,
      supplier_title: purchase_item.purchase.supplier.title.to_s,
      supplier_path: supplier_path(purchase_item.purchase.supplier),
      product_title: purchase_item.purchase.product.full_title.to_s,
      product_path: product_path(purchase_item.purchase.product),
      warehouse_name: purchase_item.warehouse.name.to_s,
      warehouse_path: warehouse_path(purchase_item.warehouse),
      expenses: helpers.format_money(helpers.safe_blank_render(purchase_item.expenses)).to_s,
      shipping_cost: helpers.format_money(helpers.safe_blank_render(purchase_item.shipping_cost)).to_s,
      tracking_number: helpers.safe_blank_render(purchase_item.tracking_number).to_s,
      shipping_company_name: helpers.safe_blank_render(purchase_item.shipping_company&.name).to_s,
      length: helpers.safe_blank_render(purchase_item.length).to_s,
      width: helpers.safe_blank_render(purchase_item.width).to_s,
      height: helpers.safe_blank_render(purchase_item.height).to_s,
      weight: helpers.safe_blank_render(purchase_item.weight).to_s,
      created_at: helpers.format_date(purchase_item.created_at).to_s,
      updated_at: helpers.format_date(purchase_item.updated_at).to_s,
      media: purchase_item.media.filter_map { |media| media_props(media) },
      warehouse_movements: purchase_item.warehouse_movements.map.with_index do |movement, index|
        {
          id: index,
          moved_in: helpers.format_datetime(movement.moved_in).to_s,
          warehouse_name: movement.warehouse&.name.to_s,
          warehouse_path: movement.warehouse ? warehouse_path(movement.warehouse) : nil
        }
      end
    }
  end

  def purchase_item_index_props(purchase_item)
    {
      id: purchase_item.id,
      path: purchase_item_path(purchase_item),
      edit_path: edit_purchase_item_path(purchase_item),
      purchase_path: purchase_path(purchase_item.purchase),
      purchase_title: purchase_item.purchase.full_title.to_s,
      product_path: product_path(purchase_item.purchase.product),
      product_title: purchase_item.purchase.product.full_title.to_s,
      variant_title: purchase_item.purchase.variant_title.to_s,
      warehouse_name: purchase_item.warehouse.name.to_s,
      warehouse_path: warehouse_path(purchase_item.warehouse),
      sale_path: purchase_item.sale ? sale_path(purchase_item.sale) : nil,
      sale_title: purchase_item.sale&.full_title.to_s,
      customer_email: purchase_item.customer&.email.to_s,
      tracking_number: helpers.safe_blank_render(purchase_item.tracking_number).to_s,
      shipping_company_name: helpers.safe_blank_render(purchase_item.shipping_company&.name).to_s,
      shipping_cost: helpers.format_money(purchase_item.shipping_cost).to_s,
      updated_at: helpers.format_date(purchase_item.updated_at).to_s
    }
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
