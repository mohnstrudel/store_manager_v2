class UsersController < ApplicationController
  before_action :redirect_if_authenticated, only: :new
  before_action :set_user, only: %i[show edit update destroy]
  allow_unauthenticated_access only: %i[new create]
  skip_before_action :authorize_resourse, only: %i[new create]
  skip_after_action :verify_authorized, only: %i[new create]

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)
    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: "Account for #{@user.email_address} was successfully created"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    user_params.delete("role") if user_params["role"] == "admin"
    if @user.update(user_params)
      redirect_to user_url(@user), notice: "User account was successfully updated"
    else
      render :edit, status: :unprocessable_entity
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
        :password,
        :password_confirmation,
        :first_name,
        :last_name,
        :role
      ]
    )
  end
end
