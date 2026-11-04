# frozen_string_literal: true

module ProductScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_product
  end

  private

  def set_product
    @product = Product.preloaded.friendly.find(params.expect(:product_id))
  end
end
