class PurchasePolicy < ApplicationPolicy
  def move?
    admin?
  end
end
