# frozen_string_literal: true

class OutboundEmailPolicy < ApplicationPolicy
  def index?
    admin? || manager?
  end

  def show?
    admin? || manager?
  end
end
