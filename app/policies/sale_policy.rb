class SalePolicy < ApplicationPolicy
  def index?
    support? || super
  end

  def show?
    support? || super
  end
end
