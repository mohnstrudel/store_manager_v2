class WarehousePolicy < ApplicationPolicy
  def change_position?
    admin?
  end
end
