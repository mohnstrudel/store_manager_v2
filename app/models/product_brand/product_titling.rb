# frozen_string_literal: true

module ProductBrand::ProductTitling
  extend ActiveSupport::Concern

  included do
    after_save :update_product_title
  end

  private

  def update_product_title
    product.update_full_title
  end
end
