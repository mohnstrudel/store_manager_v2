class PurchaseItemPolicy < ApplicationPolicy
  def move?
    admin?
  end

  def unlink?
    admin?
  end

  def edit_tracking_number?
    admin?
  end

  def cancel_tracking_number?
    admin?
  end

  def update_tracking_number?
    admin?
  end
end
