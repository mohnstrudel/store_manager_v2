# frozen_string_literal: true

module ProductHelper
  def format_relation(relationship, key)
    return "-" if relationship.blank?
    relationship.pluck(key).join(", ")
  end

  def product_timestamp_columns(record, attribute)
    columns = [{key: attribute.to_s.delete_suffix("_at"), label: "StoreMate", value: record.public_send(attribute)}]

    %i[shopify woo].each do |store_name|
      store_info = record.public_send("#{store_name}_info")
      value = store_info&.public_send("ext_#{attribute}")
      next if value.blank?

      columns << {key: store_name.to_s, label: store_name.to_s.titleize, value:}
    end

    columns
  end

  def render_product_timestamp_columns(record, attribute)
    content_tag(:div, class: "grid grid-flow-col auto-cols-max gap-6", data: {timestamp_attribute: attribute}) do
      safe_join(
        product_timestamp_columns(record, attribute).map do |column|
          content_tag(:div, class: "flex flex-col gap-1", data: {timestamp_column: column[:key]}) do
            content_tag(:span, column[:label], class: "mt-1 text-xs/1 font-medium uppercase tracking-wide text-gray-400 dark:text-gray-400") +
              content_tag(:span, format_date(column[:value]), class: "text-sm")
          end
        end
      )
    end
  end

  def product_row_class(record_id, selected_id:, hoverable: false, **extra_classes)
    class_names(extra_classes.merge(hoverable:, selected: selected_id == record_id))
  end

  def product_form_errors(product:, purchase: nil)
    errors = []

    product.errors.each do |error|
      next if %i[editions store_infos purchase].include?(error.attribute)

      errors << {label: error.attribute.to_s.humanize, message: error.message}
    end

    product.editions.each do |edition|
      edition.errors.each do |error|
        label = (error.attribute == :base) ? "Edition #{edition.title}" : "Edition #{edition.title} #{error.attribute.to_s.humanize}"
        errors << {label:, message: error.message}
      end
    end

    product.store_infos.each do |store_info|
      store_info.errors.each do |error|
        name = store_info.store_name&.titleize.presence || "New"
        label = (error.attribute == :base) ? "Store Info #{name}" : "Store Info #{name} #{error.attribute.to_s.humanize}"
        errors << {label:, message: error.message}
      end
    end

    purchase&.errors&.each do |error|
      label = (error.attribute == :base) ? "Purchase" : "Purchase #{error.attribute.to_s.humanize}"
      errors << {label:, message: error.message}
    end

    errors
  end

  def purchase_section_expanded?(purchase)
    return false if purchase.blank?
    return true if purchase.errors.any?

    purchase.supplier_id.present? ||
      purchase.order_reference.present? ||
      purchase.item_price.present? ||
      purchase.amount.present? ||
      purchase.payment_value.present?
  end
end
