# frozen_string_literal: true

class SessionPolicy < ApplicationPolicy
  def new?
    true
  end

  def destroy?
    true
  end
end
