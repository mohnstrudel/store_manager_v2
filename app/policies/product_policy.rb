# frozen_string_literal: true

class ProductPolicy < ApplicationPolicy
  def create_on_shopify?
    admin? || manager?
  end

  def push_to_shopify?
    admin? || manager?
  end

  def pull_from_shopify?
    admin? || manager?
  end

  def pull?
    admin? || manager?
  end
end
