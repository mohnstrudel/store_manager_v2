# frozen_string_literal: true

class Sale::Shopify::Catalog
  REFERENCE_KEYS = {"Product" => :product_store_id, "Variant" => :variant_store_id}.freeze
  private_constant :REFERENCE_KEYS

  def initialize(sale_items)
    @sale_items = sale_items
    @store_infos = {}
  end

  def product(store_id)
    find_store_info("Product", store_id)&.storable
  end

  def variant(store_id)
    find_store_info("Variant", store_id)&.storable
  end

  def missing_product_store_ids(order_updated_at:)
    sale_items
      .reject { |sale_item| resolved?(sale_item, order_updated_at) }
      .pluck(:product_store_id)
      .uniq
  end

  def reload
    @store_infos = {}
    self
  end

  private

  attr_reader :sale_items

  def find_store_info(type, store_id)
    return if store_id.blank?

    store_infos(type)[store_id] ||= StoreInfo.shopify.find_by(storable_type: type, store_id:)
  end

  def store_infos(type)
    @store_infos[type] ||= load_store_infos(type)
  end

  def load_store_infos(type)
    store_ids = referenced_store_ids(type)
    return {} if store_ids.empty?

    StoreInfo.shopify.where(storable_type: type, store_id: store_ids).includes(:storable).order(id: :desc).index_by(&:store_id)
  end

  def referenced_store_ids(type)
    sale_items.pluck(REFERENCE_KEYS.fetch(type)).compact_blank.uniq
  end

  def resolved?(sale_item, order_updated_at)
    return true if sale_item[:product_store_id].blank?

    product_info = store_infos("Product")[sale_item[:product_store_id]]
    return false unless product_info

    sale_item[:variant_store_id].blank? ||
      store_infos("Variant").key?(sale_item[:variant_store_id]) ||
      pulled_after?(product_info, order_updated_at)
  end

  def pulled_after?(info, time)
    time.present? && info.pull_time.present? && info.pull_time > time
  end
end
