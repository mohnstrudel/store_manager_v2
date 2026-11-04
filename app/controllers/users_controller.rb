# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]
  before_action :ensure_admin_role_is_not_assigned, only: :update

  def index
    @users = User.all

    return unless stale?(etag: [@users], last_modified: @users.maximum(:updated_at))

    render_inertia "Users/Index", serializer: Users::IndexResource, locals: {users: @users}
  end

  def show
    render_inertia "Users/Show", serializer: Users::ShowResource, locals: {user: @user}
  end

  def edit
    render_inertia "Users/Edit", serializer: Users::EditResource, locals: {user: @user}
  end

  def update
    if @user.update(user_params)
      redirect_to user_url(@user), notice: "User account was successfully updated"
    else
      redirect_to edit_user_url(@user), inertia: inertia_errors(@user.errors)
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url, notice: "User was successfully destroyed"
  end

  private

  def user_params
    params.expect(
      user: [
        :email_address,
        :first_name,
        :last_name,
        :role
      ]
    )
  end

  def set_user
    @user = User.find(params.expect(:id))
  end

  def ensure_admin_role_is_not_assigned
    head :forbidden if user_params[:role] == "admin"
  end
end
