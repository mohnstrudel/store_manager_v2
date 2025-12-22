# frozen_string_literal: true
class WarehousePolicy < ApplicationPolicy
  def change_position?
    admin?
  end
end
