# frozen_string_literal: true

module WarehouseScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_warehouse
  end

  private

  def set_warehouse
    @warehouse = policy_scope(Warehouse).find(params.expect(:warehouse_id))
  end
end
