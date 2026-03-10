# frozen_string_literal: true

module Shopable
  extend ActiveSupport::Concern

  included do
    has_many :store_infos, as: :storable, dependent: :destroy, inverse_of: :storable

    has_one :shopify_info, -> { shopify }, class_name: "StoreInfo", as: :storable,
      dependent: :destroy, inverse_of: :storable
    has_one :woo_info, -> { woo }, class_name: "StoreInfo", as: :storable,
      dependent: :destroy, inverse_of: :storable

    def shopify_published?
      shopify_info&.store_id.present?
    end
  end

  class_methods do
    def find_by_shopify_id(store_id)
      find_by_store_info(:shopify, store_id)
    end

    def find_by_woo_id(store_id)
      find_by_store_info(:woo, store_id)
    end

    private

    def find_by_store_info(store_name, store_id)
      return if store_id.blank?

      store_info = StoreInfo.find_by(store_name: store_name, store_id: store_id, storable_type: name)

      store_info&.storable
    end
  end
end
