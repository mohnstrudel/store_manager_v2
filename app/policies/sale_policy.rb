class SalePolicy < ApplicationPolicy
  def index?
    support? || super
  end

  def show?
    support? || super
  end

  class Scope < Scope
    def resolve
      if admin? || manager? || support?
        scope.all
      else
        scope.none
      end
    end
  end
end
