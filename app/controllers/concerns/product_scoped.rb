# frozen_string_literal: true

module ProductScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_product
  end

  private

  def set_product
    @product = Product.for_details.friendly.find(params[:product_id])
  end
end
