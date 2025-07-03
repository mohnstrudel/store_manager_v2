class PurchaseItemPolicy < ApplicationPolicy
  def move?
    admin?
  end
end
