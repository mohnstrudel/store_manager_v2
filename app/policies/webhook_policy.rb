class WebhookPolicy < ApplicationPolicy
  def process_order?
    true
  end
end
