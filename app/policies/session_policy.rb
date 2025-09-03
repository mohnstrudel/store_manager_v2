class SessionPolicy < ApplicationPolicy
  # We allow everyone to sign in
  def new?
    true
  end

  # ...and to log out
  def destroy?
    true
  end
end
