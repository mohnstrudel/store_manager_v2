# frozen_string_literal: true

module PurchaseItemScoped
  extend ActiveSupport::Concern

  included do
    before_action :set_purchase_item
  end

  private

  def set_purchase_item
    @purchase_item = PurchaseItem.with_media.find(params[:purchase_item_id])
  end
end
