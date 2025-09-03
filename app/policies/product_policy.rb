class ProductPolicy < ApplicationPolicy
  def pull?
    admin? || manager?
  end
end
