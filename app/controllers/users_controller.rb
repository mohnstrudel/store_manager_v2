# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = User.all
    render inertia: "Users/Index", props: {
      users: @users.map { |user| helpers.user_props(user) }
    }
  end

  def show
    render inertia: "Users/Show", props: {
      user: helpers.user_props(@user)
    }
  end

  def edit
    render inertia: "Users/Edit", props: {
      user: {
        id: @user.id,
        email_address: @user.email_address,
        first_name: @user.first_name,
        last_name: @user.last_name,
        role: @user.role,
        path: user_path(@user)
      },
      role_options: User.role_options_for_select,
      is_admin: @user.admin?
    }
  end

  def update
    user_params.delete("role") if user_params["role"] == "admin"
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

  def set_user
    @user = User.find(params.expect(:id))
  end

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
end
