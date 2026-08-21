# frozen_string_literal: true

class VariantAssignmentIssuePolicy < ApplicationPolicy
  def index? = admin?
  def update? = admin?
end
