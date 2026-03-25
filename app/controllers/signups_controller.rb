# frozen_string_literal: true

class SignupsController < ApplicationController
  before_action :redirect_if_authenticated, only: :new
  allow_unauthenticated_access only: %i[new create]

  def new
    @user = User.new
    render "users/new"
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user
      redirect_to noop_path, notice: "Account for #{@user.email_address} was successfully created"
    else
      render "users/new", status: :unprocessable_content
    end
  end

  private

  def authorize_resourse
    authorize :user
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
