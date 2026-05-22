# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = User.all
    render inertia: "Users/Index", props: {
      users: @users.map { |user| user_props(user) }
    }
  end

  def show
    render inertia: "Users/Show", props: {
      user: user_props(@user)
    }
  end

  def edit
  end

  def update
    user_params.delete("role") if user_params["role"] == "admin"
    if @user.update(user_params)
      redirect_to user_url(@user), notice: "User account was successfully updated"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url, notice: "User was successfully destroyed"
  end

  private

  def set_user
    @user = User.find(params[:id])
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

  def user_props(user)
    {
      id: user.id,
      email_address: user.email_address.to_s,
      first_name: user.first_name.presence || "-",
      last_name: user.last_name.presence || "-",
      role: user.role.humanize,
      created_at: helpers.format_date(user.created_at).to_s,
      updated_at: helpers.format_date(user.updated_at).to_s,
      path: user_path(user),
      edit_path: edit_user_path(user),
      destroy_path: user_path(user)
    }
  end
end
