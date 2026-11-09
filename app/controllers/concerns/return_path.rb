# frozen_string_literal: true

module ReturnPath
  extend ActiveSupport::Concern

  private

  def return_path
    url_from(params[:return_to]) || default_return_path
  end
end
