# frozen_string_literal: true

module Warehouses
  class PositionsController < ApplicationController
    include WarehouseScoped

    def update
      new_position = params[:position].to_i

      return head :bad_request unless new_position.positive?

      prev_position = @warehouse.position
      @warehouse.update_position!(new_position)

      respond_to do |format|
        format.html do
          redirect_to warehouses_url,
            notice: "We changed \"#{@warehouse.name}\" position from #{prev_position} to #{new_position}",
            status: :see_other
        end
        format.json { head :ok }
      end
    rescue ActiveRecord::RecordInvalid
      respond_to do |format|
        format.html { redirect_to warehouses_url, alert: "Failed to update position", status: :unprocessable_content }
        format.json { head :unprocessable_content }
      end
    end

    private

    def authorize_resourse
      authorize :warehouse, :change_position?
    end
  end
end
