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

  def turbo_replace_purchase_item(field, partial)
    turbo_stream.replace(
      helpers.dom_id(@purchase_item, field),
      partial: "purchase_items/#{partial}",
      locals: {purchase_item: @purchase_item}
    )
  end
end
