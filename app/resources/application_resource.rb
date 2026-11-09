# frozen_string_literal: true

class ApplicationResource
  include Alba::Resource
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::NumberHelper
  include FormattingHelper
  include UiHelper
  include StoreAdminLinksHelper
  include PurchaseProductHelper

  helper Typelizer::DSL
  helper Alba::Inertia::Resource

  ACTIVE_STORAGE_ROUTABLES = [
    ActiveStorage::Blob, ActiveStorage::Attachment, ActiveStorage::Preview,
    ActiveStorage::Variant, ActiveStorage::VariantWithRecord
  ].freeze

  def url_for(options)
    case options
    when Hash, String then super
    when *ACTIVE_STORAGE_ROUTABLES then route_for(ActiveStorage.resolve_model_to_route, options, only_path: true)
    else polymorphic_path(options)
    end
  end
end
