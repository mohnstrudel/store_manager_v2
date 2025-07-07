class PurchaseItemPolicy < ApplicationPolicy
  def move?
    admin?
  end

  def unlink?
    admin?
  end
end
