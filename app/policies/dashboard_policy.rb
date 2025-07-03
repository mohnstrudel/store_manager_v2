class DashboardPolicy < ApplicationPolicy
  def debts?
    admin? || manager?
  end
end
