# frozen_string_literal: true

module Mcp
  class BaseController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :require_authentication
    skip_before_action :set_sentry_user
    skip_before_action :authorize_resourse
    skip_after_action :verify_authorized
  end
end
