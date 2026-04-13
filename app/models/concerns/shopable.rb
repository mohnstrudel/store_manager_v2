# frozen_string_literal: true

module Shopable
  extend ActiveSupport::Concern

  included do
    has_many :store_infos, as: :storable, dependent: :destroy, inverse_of: :storable

    has_one :shopify_info, -> { shopify }, class_name: "StoreInfo", as: :storable,
      dependent: :destroy, inverse_of: :storable
    has_one :woo_info, -> { woo }, class_name: "StoreInfo", as: :storable,
      dependent: :destroy, inverse_of: :storable
  end

  def update_or_create_store_info!(store_name:, **attributes)
    store_info = store_infos.find_or_initialize_by(store_name:)
    store_info.assign_attributes(attributes)
    store_info.save!
    store_info
  end

  def link_shopify_info!(**attributes)
    update_or_create_store_info!(store_name: :shopify, **attributes)
  end

  def mark_shopify_pushed!(at: Time.current)
    update_or_create_store_info!(store_name: :shopify, push_time: at)
  end

  def mark_shopify_pulled!(at: Time.zone.now)
    update_or_create_store_info!(store_name: :shopify, pull_time: at)
  end

  def shopify_linked?
    shopify_info&.store_id.present?
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
