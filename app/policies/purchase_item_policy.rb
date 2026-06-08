# frozen_string_literal: true

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

  def edit_shipping_company?
    admin?
  end

  def cancel_edit_shipping_company?
    admin?
  end

  def update_shipping_company?
    admin?
  end

  def update_shipping_cost?
    admin?
  end

  def update_shipping_details?
    admin?
  end
end
