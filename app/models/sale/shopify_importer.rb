# frozen_string_literal: true

class Sale
  class ShopifyImporter
    class ImportError < StandardError; end

    attr_reader :parsed, :sale
    private :parsed, :sale

    def self.import!(parsed_payload)
      raise ArgumentError, "Parsed payload cannot be blank" if parsed_payload.blank?

      new(parsed_payload).import!
    end

    def initialize(parsed_payload)
      @parsed = parsed_payload
    end

    def import!
      raise ArgumentError, "Parsed payload cannot be blank" if @parsed.blank?

      import_internal
    end

    private

    def import_internal
      ActiveRecord::Base.transaction do
        prepare_customer
        prepare_sale
        update_shopify_store_info!
        update_or_create_sale_items!
        linked_ids = sale.link_with_purchase_items
        notify_customers(linked_ids)
      end
    rescue ActiveRecord::RecordInvalid => e
      model_name = e.record.class.name
      detailed_errors = e.record.errors.full_messages.join(", ")
      raise ImportError, "Failed to process #{model_name}: #{detailed_errors}"
    end

    def prepare_customer
      @customer = Customer::ShopifyImporter.import_from_shopify(
        @parsed[:customer],
        @parsed[:customer_store_info]
      )
    end

    def prepare_sale
      @sale = find_or_initialize_sale
      @sale.assign_attributes(sale_attributes)
      @sale.save!
    end

    def find_or_initialize_sale
      Sale.find_by_shopify_id(@parsed[:sale][:shopify_id]) || Sale.new
    end

    def sale_attributes
      @parsed[:sale].merge(customer: @customer)
    end

    def update_shopify_store_info!
      return if @parsed[:sale][:shopify_id].blank?

      store_info = @sale.shopify_info || @sale.store_infos.shopify.new

      store_info.assign_attributes(
        store_id: @parsed[:sale][:shopify_id],
        pull_time: Time.zone.now,
        ext_created_at: @parsed[:store_info][:ext_created_at],
        ext_updated_at: @parsed[:store_info][:ext_updated_at]
      )

      store_info.save!
    end

    def update_or_create_sale_items!
      @parsed[:sale_items].each do |parsed_sale_item|
        if having_only_product_title?(**parsed_sale_item)
          product = create_product_with(parsed_sale_item[:full_title])
          edition = find_or_create_edition_with(parsed_sale_item[:edition_title], product)
        else
          product = find_or_create_product!(parsed_sale_item[:shopify_product_id], parsed_sale_item[:product])
          edition = find_or_create_edition!(parsed_sale_item[:shopify_edition_id], parsed_sale_item[:product], product)
        end

        sale_item = SaleItem.find_by(shopify_id: parsed_sale_item[:shopify_id]) || SaleItem.new

        sale_item.assign_attributes(
          price: parsed_sale_item[:price],
          qty: parsed_sale_item[:qty],
          product: product,
          edition: edition,
          sale: @sale,
          shopify_id: parsed_sale_item[:shopify_id]
        )

        sale_item.save!
      end
    end

    def having_only_product_title?(full_title:, shopify_product_id:, shopify_edition_id:, **)
      full_title.present? && shopify_edition_id.blank? && shopify_product_id.blank?
    end

    def create_product_with(parsed_title)
      Shopify::ProductFromTitleCreator.new(api_title: parsed_title).call
    end

    def find_or_create_product!(shopify_product_id, parsed_product)
      return nil if shopify_product_id.blank? || parsed_product.blank?

      Product.find_by_shopify_id(shopify_product_id) ||
        Product::ShopifyImporter.import!(parsed_product)
    end

    def find_or_create_edition_with(edition_title, product)
      return nil if edition_title.blank?

      existing_edition = product.editions.find { |e| e.title == edition_title }
      return existing_edition if existing_edition

      product.versions.create!(value: edition_title)
      product.build_editions
      product.save!
      product.editions.last
    end

    def find_or_create_edition!(shopify_edition_id, parsed_product, product)
      return nil if shopify_edition_id.blank?

      existing_edition = Edition.find_by_shopify_id(shopify_edition_id)
      return existing_edition if existing_edition

      return nil unless parsed_product && parsed_product[:editions]

      parsed_product[:editions].map do |parsed_edition|
        Edition::ShopifyImporter.import!(product, parsed_edition)
      end.find { |e| e.shopify_info&.store_id == shopify_edition_id }
    end

    def notify_customers(linked_ids)
      PurchasedNotifier.handle_product_purchase(purchase_item_ids: linked_ids)
    end
  end
end
