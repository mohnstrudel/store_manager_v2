class SalePolicy < ApplicationPolicy
  def index?
    support? || super
  end

  def show?
    support? || super
  end

  def pull?
    admin? || manager? || support?
  end

  def link_purchase_items?
    admin?
  end
end
