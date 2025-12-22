# frozen_string_literal: true
class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin?
  end

  # We allow everyone to create an account
  def new?
    true
  end

  def create?
    true
  end
end
