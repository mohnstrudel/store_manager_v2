# frozen_string_literal: true

class SmokeController < ApplicationController
  skip_before_action :authorize_resource
  skip_after_action :verify_authorized

  def index
    render inertia: "Hello/Index"
  end
end
