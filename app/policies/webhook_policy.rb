class WebhookPolicy < ApplicationPolicy
  def process_order?
    true
  end

  def sale_status?
    true
  end
end
