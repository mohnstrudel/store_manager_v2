# frozen_string_literal: true

class SalesTagPolicy < ApplicationPolicy
  def index?
    staff?
  end

  def show?
    staff?
  end

  def create?
    staff?
  end

  private

  def staff?
    admin? || manager? || support?
  end
end
