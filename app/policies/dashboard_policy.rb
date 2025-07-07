class DashboardPolicy < ApplicationPolicy
  def debts?
    admin? || manager?
  end

  def pull_last_orders?
    admin? || manager? || support?
  end
end
