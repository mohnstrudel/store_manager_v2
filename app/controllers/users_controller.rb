# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy]

  def index
    @users = User.all
  end

  def show
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
end
