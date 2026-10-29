# frozen_string_literal: true

module Sales
  class TaggingsController < ApplicationController
    LOCAL_RETURN_PATH = %r{\A/sales(?:/[[:graph:]&&[^?#\\]]*)?(?:\?[[:graph:]&&[^#\\]]*)?\z}
    DOT_SEGMENT = /\A(?:\.|%2e){1,2}\z/i

    before_action :set_sale

    def update
      tagging = tagging_params
      reject_unreadable!(tagging)

      @sale.replace_tags!(ids: tagging[:ids], original_ids: tagging[:original_ids])
      redirect_to return_path, notice: "Tags saved", status: :see_other
    rescue ActiveRecord::RecordInvalid
      redirect_to return_path, inertia: inertia_errors(@sale.errors), status: :see_other
    end

    private

    def tagging_params
      sale = params[:sale]
      tagging = sale[:tagging] if sale.is_a?(ActionController::Parameters)
      tagging.is_a?(ActionController::Parameters) ? tagging : ActionController::Parameters.new
    end

    def reject_unreadable!(tagging)
      return if tagging[:submitted] == "1" && tagging[:new_tags].blank?

      @sale.errors.add(:tags, Sale::Tagging::UNREADABLE_INPUT_MESSAGE)
      raise ActiveRecord::RecordInvalid, @sale
    end

    def return_path
      candidate = params[:return_to].to_s
      local_sales_path?(candidate) ? candidate : sale_path(@sale)
    end

    def local_sales_path?(candidate)
      path = candidate.split("?", 2).first
      candidate.match?(LOCAL_RETURN_PATH) && path.exclude?("//") && path.split("/").none?(DOT_SEGMENT)
    end

    def authorize_resource
      authorize :sale, :update_tags?
    end

    def set_sale
      @sale = policy_scope(Sale).friendly.find(params.expect(:sale_id))
    end
  end
end
