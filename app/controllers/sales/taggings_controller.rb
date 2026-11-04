# frozen_string_literal: true

module Sales
  class TaggingsController < ApplicationController
    include ReturnPath

    before_action :set_sale

    def update
      tagging = tagging_params
      reject_unreadable(tagging)

      @sale.retag(ids: tagging[:ids], original_ids: tagging[:original_ids])
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

    def reject_unreadable(tagging)
      return if tagging[:submitted] == "1" && tagging[:new_tags].blank?

      @sale.errors.add(:tags, Sale::Taggable::UNREADABLE_INPUT_MESSAGE)
      raise ActiveRecord::RecordInvalid, @sale
    end

    def default_return_path
      sale_path(@sale)
    end

    def authorize_resource
      authorize :sale, :update_tags?
    end

    def set_sale
      @sale = policy_scope(Sale).friendly.find(params.expect(:sale_id))
    end
  end
end
