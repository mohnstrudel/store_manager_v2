# frozen_string_literal: true

class ApplicationResource
  include Alba::Resource
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::NumberHelper
  include FormattingHelper
  include UiHelper
  include StoreAdminLinksHelper

  helper Typelizer::DSL
  helper Alba::Inertia::Resource

  def url_for(options)
    (options.is_a?(Hash) || options.is_a?(String)) ? super : polymorphic_path(options)
  end
end
