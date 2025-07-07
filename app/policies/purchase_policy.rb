class PurchasePolicy < ApplicationPolicy
  def move?
    admin?
  end

  def product_editions?
    admin?
  end
end
