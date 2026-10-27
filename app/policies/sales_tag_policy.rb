# frozen_string_literal: true

class SalesTagPolicy < ApplicationPolicy
  def index?
    admin?
  end
end
