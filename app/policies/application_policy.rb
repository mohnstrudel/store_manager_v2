# frozen_string_literal: true
class ApplicationPolicy
  attr_reader :user, :record
  delegate :guest?, :admin?, :manager?, :support?, to: :user, allow_nil: true

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    admin? || manager?
  end

  def show?
    admin? || manager?
  end

  def create?
    admin?
  end

  def new?
    create?
  end

  def update?
    admin?
  end

  def edit?
    update?
  end

  def destroy?
    admin?
  end

  class Scope
    delegate :guest?, :admin?, :manager?, :support?, to: :user

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      if admin? || manager? || support?
        scope.all
      else
        scope.none
      end
    end

    private

    attr_reader :user, :scope
  end
end
