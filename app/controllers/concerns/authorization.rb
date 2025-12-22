# frozen_string_literal: true
module Authorization
  extend ActiveSupport::Concern
  include Pundit::Authorization

  included do
    before_action :authorize_resourse
    after_action :verify_authorized
    rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  end

  private

  def authorize_resourse
    resourse = controller_name.singularize.to_sym
    authorize resourse
  end

  def user_not_authorized
    page_name = controller_name.humanize
    flash[:error] = "You don't have permission to view the #{page_name} page"
    redirect_back_or_to noop_path
  end
end
