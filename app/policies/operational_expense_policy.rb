# frozen_string_literal: true

class OperationalExpensePolicy < ApplicationPolicy
  def index? = admin?
  def show? = admin?

  class Scope < ApplicationPolicy::Scope
    def resolve = admin? ? scope.all : scope.none
  end
end
