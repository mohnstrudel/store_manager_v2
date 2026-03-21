# frozen_string_literal: true

class Sale::Shopify::Importer
  class Error < StandardError; end

  attr_reader :sale, :parsed
  private :sale, :parsed

  def self.import!(parsed_payload)
    raise ArgumentError, "Parsed payload cannot be blank" if parsed_payload.blank?

    new(parsed_payload).update_or_create!
  end

  def initialize(parsed_payload)
    @parsed = parsed_payload
  end

  def update_or_create!
    find_or_initialize_sale

    ActiveRecord::Base.transaction do
      sale.update!(sale_attributes)
      update_or_create_store_info!
      update_or_create_sale_items!
    end

    handle_post_import_actions
    sale
  rescue ActiveRecord::RecordInvalid => e
    handle_record_invalid(e)
  end

  private

  def find_or_initialize_sale
    @sale = Sale.find_by_shopify_id(parsed[:store_info][:store_id]) || Sale.new
  end

  def sale_attributes
    parsed[:sale].merge(customer: Customer::Shopify::Importer.import!(parsed[:customer]))
  end

  def update_or_create_store_info!
    store_info = sale.shopify_info || sale.store_infos.shopify.new
    store_info.assign_attributes(**parsed[:store_info], pull_time: Time.zone.now)
    store_info.save!
  end

  def update_or_create_sale_items!
    parsed[:sale_items].each do |parsed_sale_item|
      Sale::Shopify::SaleItemImporter.new(sale, parsed_sale_item).import!
    end
  end

  def handle_post_import_actions
    return unless should_link_items?

    linked_ids = sale.link_with_purchase_items
    PurchaseItem::Notifier.handle_product_purchase(purchase_item_ids: linked_ids) if linked_ids.any?
  end

  def should_link_items?
    sale.active? || sale.completed?
  end

  def handle_record_invalid(error)
    model_name = error.record.class.name
    detailed_errors = error.record.errors.full_messages.join(", ")
    store_id_details = "Sale store_id: #{parsed[:store_info][:store_id]}"
    raise Error, "Failed to process #{model_name}: #{detailed_errors}\n#{store_id_details}"
  end
end
