# frozen_string_literal: true

module Franchise::ProductTitling
  extend ActiveSupport::Concern

  included do
    after_save :update_products
  end

  private

  def update_products
    products.each(&:update_full_title)
  end
end
