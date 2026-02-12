# frozen_string_literal: true

class Sale
  class ShopifyImporter
    class SaleShopifyImporterError < StandardError; end

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

      sale.reload

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
      parsed[:sale].merge(customer: Customer::ShopifyImporter.import!(parsed[:customer]))
    end

    def update_or_create_store_info!
      store_info = sale.shopify_info || sale.store_infos.shopify.new
      store_info.assign_attributes(
        **parsed[:store_info],
        pull_time: Time.zone.now
      )
      store_info.save!
    end

    def update_or_create_sale_items!
      parsed[:sale_items].each do |parsed_sale_item|
        SaleItemImporter.new(sale, parsed_sale_item).import!
      end
    end

    def handle_post_import_actions
      return unless should_link_items?

      linked_ids = sale.link_with_purchase_items
      notify_customers(linked_ids) if linked_ids.any?
    end

    def should_link_items?
      sale.active? || sale.completed?
    end

    def notify_customers(linked_ids)
      PurchasedNotifier.handle_product_purchase(purchase_item_ids: linked_ids)
    end

    def handle_record_invalid(e)
      model_name = e.record.class.name
      detailed_errors = e.record.errors.full_messages.join(", ")
      store_id_details = "Sale store_id: #{parsed[:store_info][:store_id]}"
      raise SaleShopifyImporterError, "Failed to process #{model_name}: #{detailed_errors}\n#{store_id_details}"
    end

    class SaleItemImporter
      attr_reader :sale_item, :sale, :parsed
      private :sale_item, :sale, :parsed

      def initialize(sale, parsed_sale_item)
        @sale = sale
        @parsed = parsed_sale_item
      end

      def import!
        return if having_no_product_data?

        find_or_initialize_sale_item
        return create_title_only_sale_item! if having_only_product_title?

        ActiveRecord::Base.transaction do
          sale_item.assign_attributes(sale_item_attributes)
          sale_item.save!
        end

        sale_item
      rescue ActiveRecord::RecordInvalid => e
        handle_record_invalid(e)
      end

      private

      def having_no_product_data?
        parsed[:product_store_id].blank? && parsed[:product].blank? && parsed[:full_title].blank?
      end

      def find_or_initialize_sale_item
        @sale_item = SaleItem.find_by(shopify_id: parsed[:store_id]) || SaleItem.new
      end

      def having_only_product_title?
        parsed[:full_title].present? &&
          parsed[:edition_store_id].blank? &&
          parsed[:product_store_id].blank?
      end

      def create_title_only_sale_item!
        product = create_product_from_full_title
        edition = create_custom_edition_for_product(product)

        return unless product || edition

        sale_item.assign_attributes({
          price: parsed[:price],
          qty: parsed[:qty],
          shopify_id: parsed[:store_id],
          sale: sale,
          product:,
          edition:
        }.compact)
        sale_item.save!

        sale_item
      end

      def create_product_from_full_title
        return nil if parsed[:full_title].blank?

        parsed_product = Product::ShopifyParser.parse({"title" => parsed[:full_title]})
        Product::ShopifyImporter.import!(parsed_product)
      end

      def create_custom_edition_for_product(product)
        return nil if product.blank?

        existing_edition = product.editions.joins(:version)
          .find_by(versions: {value: parsed[:edition_title]})
        return existing_edition if existing_edition

        version = product.versions.create!(value: parsed[:edition_title])
        product.editions.create!(version:, color: nil, size: nil)
      end

      def sale_item_attributes
        {
          price: parsed[:price],
          qty: parsed[:qty],
          shopify_id: parsed[:store_id],
          sale: sale,
          product: imported_product,
          edition: imported_edition
        }.compact
      end

      def imported_product
        return nil if parsed[:product_store_id].blank? || parsed[:product].blank?

        Product.find_by_shopify_id(parsed[:product_store_id]) ||
          Product::ShopifyImporter.import!(parsed[:product])
      end

      def imported_edition
        return find_or_create_edition_from_shopify if parsed[:edition_store_id].present?
        return nil if parsed[:edition_title].blank?

        create_custom_edition_for_product(imported_product)
      end

      def find_or_create_edition_from_shopify
        existing_edition = Edition.find_by_shopify_id(parsed[:edition_store_id])
        return existing_edition if existing_edition

        return nil unless parsed[:product] && parsed[:product][:editions]

        parsed[:product][:editions].map do |parsed_edition|
          Edition::ShopifyImporter.import!(imported_product, parsed_edition)
        end.find { |e| e.shopify_info&.store_id == parsed[:edition_store_id] }
      end

      def handle_record_invalid(e)
        model_name = e.record.class.name
        detailed_errors = e.record.errors.full_messages.join(", ")
        raise SaleShopifyImporterError, "Failed to process #{model_name}: #{detailed_errors}"
      end
    end
  end
end
