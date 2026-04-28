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
    association(:"#{store_name}_info").target = store_info if respond_to?(:"#{store_name}_info")
    store_info
  end

  def woo_store_id
    woo_info&.store_id
  end

  def shopify_store_id
    shopify_info&.store_id
  end

  def upsert_woo_info!(**attributes)
    update_or_create_store_info!(store_name: :woo, **attributes)
  end

  def upsert_shopify_info!(**attributes)
    update_or_create_store_info!(store_name: :shopify, **attributes)
  end

  def mark_shopify_pushed!(at: Time.current)
    upsert_shopify_info!(push_time: at)
  end

  def mark_shopify_pulled!(at: Time.zone.now)
    upsert_shopify_info!(pull_time: at)
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

    def where_woo_ids(store_ids)
      joins(:woo_info).where(store_infos: {store_name: StoreInfo.store_names[:woo], store_id: Array(store_ids)})
    end

    private

    def find_by_store_info(store_name, store_id)
      return if store_id.blank?

      store_info = StoreInfo.find_by(store_name: store_name, store_id: store_id, storable_type: name)

      store_info&.storable
    end
  end

end
