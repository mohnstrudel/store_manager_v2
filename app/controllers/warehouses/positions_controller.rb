# frozen_string_literal: true

module Warehouses
  class PositionsController < ApplicationController
    include WarehouseScoped

    def update
      new_position = params.expect(:position).to_i

      return head :bad_request unless new_position.positive?

      prev_position = @warehouse.position
      @warehouse.move_to_position(new_position)

      redirect_to warehouses_url,
        notice: "We changed \"#{@warehouse.name}\" position from #{prev_position} to #{new_position}",
        status: :see_other
    rescue ActiveRecord::RecordInvalid
      redirect_to warehouses_url, alert: "Failed to update position", status: :unprocessable_content
    end

    private

    def authorize_resource
      authorize :warehouse, :change_position?
    end
  end
end
