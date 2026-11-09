# frozen_string_literal: true

class BrokenSalePolicy < ApplicationPolicy
  def index? = admin?
  def update? = admin?
end
