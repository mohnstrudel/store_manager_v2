# frozen_string_literal: true

module Warehouses
  class PositionsController < ApplicationController
    include WarehouseScoped

    before_action :ensure_position_is_positive

    def update
      prev_position = @warehouse.position
      @warehouse.move_to_position(new_position)

      redirect_to warehouses_url,
        notice: "We changed \"#{@warehouse.name}\" position from #{prev_position} to #{new_position}",
        status: :see_other
    rescue ActiveRecord::RecordInvalid
      redirect_to warehouses_url, alert: "Failed to update position", status: :unprocessable_content
    end

    private

    def new_position
      @new_position ||= params.expect(:position).to_i
    end

    def ensure_position_is_positive
      head :bad_request unless new_position.positive?
    end

    def authorize_resource
      authorize :warehouse, :change_position?
    end
  end
end
