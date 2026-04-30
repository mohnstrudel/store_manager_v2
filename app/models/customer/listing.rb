# frozen_string_literal: true

module Customer::Listing
  extend ActiveSupport::Concern

  included do
    scope :for_listing, -> { includes(:woo_info) }
  end
end
