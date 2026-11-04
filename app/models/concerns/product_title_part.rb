# frozen_string_literal: true

module ProductTitlePart
  extend ActiveSupport::Concern

  included do
    after_save :retitle_products
  end

  private

  def retitle_products
    titled_products.each(&:update_full_title)
  end
end
