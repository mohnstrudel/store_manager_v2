# frozen_string_literal: true

module Sales
  class ItemsController < ApplicationController
    before_action :set_sale
    before_action :set_sale_item, only: %i[show edit update destroy]
    before_action :load_form_collections, only: :edit

    def show
      render "sale_items/show"
    end

    def edit
    end

    def update
      attachments = ActiveStorage::Attachment.where(id: params[:deleted_img_ids]) if params[:deleted_img_ids].present?

      if @sale_item.update(sale_item_params)
        attachments&.map(&:purge_later)
        redirect_to sale_item_path(@sale, @sale_item), notice: "Sale item was successfully updated", status: :see_other
      else
        load_form_collections
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      warehouse = @sale_item.warehouse
      @sale_item.destroy!

      redirect_to warehouse, notice: "Sale item was successfully destroyed", status: :see_other, turbolinks: false
    end

    private

    def authorize_resourse
      authorize :sale_item
    end

    def set_sale
      @sale = Sale.friendly.find(params[:sale_id])
    end

    def set_sale_item
      @sale_item = if action_name == "show"
        @sale.sale_items.for_details.find(params[:id])
      else
        @sale.sale_items.find(params[:id])
      end
    end

    def sale_item_params
      params.expect(
        sale_item: [:price,
          :qty,
          :sale_id,
          :edition_id,
          :woo_id]
      )
    end

    def load_form_collections
      @purchases = Purchase.for_form_select
    end
  end
end
