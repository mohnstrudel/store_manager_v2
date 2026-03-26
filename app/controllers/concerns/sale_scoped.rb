# frozen_string_literal: true

module SaleScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_sale
  end

  private

  def set_sale
    @sale = Sale.friendly.find(params[:sale_id])
  end
end
