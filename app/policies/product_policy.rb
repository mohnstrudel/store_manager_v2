# frozen_string_literal: true
class ProductPolicy < ApplicationPolicy
  def pull?
    admin? || manager?
  end
end
