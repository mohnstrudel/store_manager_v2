# frozen_string_literal: true

module ProductHelper
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

  def product_props(product)
    {
      id: product.id,
      full_title: product.full_title,
      path: product_path(product)
    }
  end

  def index_product_props(product)
    {
      id: product.id,
      title: product.title,
      full_title: product.full_title,
      path: product_path(product),
      edit_path: edit_product_path(product),
      thumb_url: thumb_url(product),
      variants: product.variants.reject(&:base_model?).map { |variant|
        {
          id: variant.id,
          title: variant.title
        }
      },
      woo_store_id: product.woo_info&.store_id,
      shopify_id_short: product.shopify_info&.id_short,
      new_purchase_path: new_purchase_path(product:)
    }
  end

  def show_product_props(product, can_pull_from_shopify:)
    {
      id: product.id,
      title: product.title,
      full_title: product.full_title,
      path: product_path(product),
      edit_path: edit_product_path(product),
      franchise: {id: product.franchise_id, title: product.franchise.title},
      brands: product.brands.map { |brand| {id: brand.id, title: brand.title} },
      sizes: product.sizes.map { |size| {id: size.id, value: size.value} },
      versions: product.versions.map { |version| {id: version.id, value: version.value} },
      colors: product.colors.map { |color| {id: color.id, value: color.value} },
      shape: product.shape,
      description_html: product.description.body&.to_html,
      media: product.media.filter_map { |media| media_props(media) },
      shopify_info: shopify_info_props(product),
      woo_info: woo_info_props(product),
      created_at_columns: product_timestamp_columns_props(product, :created_at),
      updated_at_columns: product_timestamp_columns_props(product, :updated_at),
      shopify_linked: product.shopify_linked?,
      can_pull_from_shopify: can_pull_from_shopify,
      shopify_pull_path: product_shopify_pull_path(product),
      new_purchase_path: new_purchase_path(product:)
    }
  end

  def product_timestamp_columns_props(product, attribute)
    product_timestamp_columns(product, attribute).map do |column|
      {
        key: column[:key],
        label: column[:label],
        value: format_date(column[:value])
      }
    end
  end

  def shopify_info_props(product)
    info = product.shopify_info
    return nil unless info

    {
      store_id: info.store_id,
      id_short: info.id_short,
      tag_list: info.tag_list,
      product_url: product.build_shopify_url
    }
  end

  def woo_info_props(product)
    info = product.woo_info
    return nil unless info

    {
      store_id: info.store_id,
      product_url: info.product_url
    }
  end

  def variant_props(variant, sales_sums, purchase_sums, purchase_cost_totals, can_view_profitability: false, expense_fraction: ExpenseRate.combined_fraction)
    purchase_totals = purchase_cost_totals[variant.id]

    {
      id: variant.id,
      title: variant.title,
      types_name: variant.types_name,
      weight: variant.weight.to_f,
      purchase_cost: variant.purchase_cost.to_f,
      selling_price: variant.selling_price.to_f,
      deactivated: variant.deactivated?,
      active_sales_count: sales_sums[variant.id].to_i,
      purchases_count: purchase_sums[variant.id].to_i,
      shopify_id_short: variant.shopify_info&.id_short,
      woo_store_id: variant.woo_info&.store_id,
      total_purchase_cost: can_view_profitability && purchase_totals ? format_money(purchase_totals[:cost]) : nil,
      theoretical_profit: can_view_profitability ? variant_theoretical_profit(variant, purchase_totals, expense_fraction) : nil
    }
  end

  def variant_theoretical_profit(variant, purchase_totals, expense_fraction)
    return nil if purchase_totals.nil? || purchase_totals[:units].zero?

    selling_price = variant.selling_price.to_d
    return nil if selling_price.zero?

    average_landed_cost = purchase_totals[:cost] / purchase_totals[:units]
    format_money(selling_price - average_landed_cost - (selling_price * expense_fraction))
  end

  def product_sale_item_props(sale_item, product)
    sale = sale_item.sale
    purchase_item = sale_item.purchase_items.first
    store_type, store_id = product_sale_info_for_sale(sale)

    {
      id: sale_item.id,
      sale_path: sale_path(sale),
      store_type: store_type,
      store_id: store_id.presence || "",
      customer_name: sale.customer.full_name,
      customer_email: sale.customer.email,
      country: sale.shipping_address&.country.presence || "",
      date: format_date(sale.woo_created_at.presence || sale_item.created_at),
      variant_title: product.variants.any? ? sale_item.variant&.title : nil,
      price: format_money(sale_item.price),
      qty: sale_item.qty,
      status: sale.status,
      warehouse: purchase_item&.warehouse&.name.presence || "",
      purchase_item_path: purchase_item ? purchase_item_path(purchase_item) : nil
    }
  end

  def product_sale_info_for_sale(sale)
    return [nil, nil] unless sale

    if sale.shopify_info&.store_id.present?
      ["shopify", sale.shopify_info.id_short]
    elsif sale.woo_info&.store_id.present?
      ["woo", sale.woo_info.store_id]
    else
      [nil, sale.shopify_name.presence || sale.woo_store_id]
    end
  end

  def purchase_props(purchase)
    {
      id: purchase.id,
      path: purchase_path(purchase),
      supplier: purchase.supplier.title,
      order_reference: purchase.order_reference.to_s,
      variant_title: purchase.variant&.title,
      item_price: format_money(purchase.item_price),
      amount: purchase.amount,
      created_at: format_date(purchase.created_at),
      warehouses: purchase.purchase_items.map { |purchase_item|
        {
          id: purchase_item.id,
          name: purchase_item.warehouse&.name
        }
      }
    }
  end

  def product_profitability_props(product)
    expense_fraction = ExpenseRate.combined_fraction
    summary = product.profitability(expense_fraction:)

    {
      potential_sales: format_money(summary[:potential_sales]),
      expected_total_cost: format_money(summary[:expected_total_cost]),
      expected_net_profit: format_money(summary[:expected_net_profit]),
      received_revenue: format_money(summary[:received_revenue]),
      purchase_paid: format_money(summary[:purchase_paid]),
      cash_position: format_money(summary[:cash_position])
    }
  end

  def product_form_props(product)
    {
      product: form_product_props(product),
      options: form_options_props
    }
  end

  def form_product_props(product)
    {
      id: product.id,
      title: product.title,
      description_html: product.description.body&.to_html,
      franchise_id: product.franchise_id,
      shape: product.shape,
      brand_ids: product.brand_ids,
      path: product.persisted? ? product_path(product) : "",
      variants: product.variants.map { |variant| form_variant_props(variant) },
      store_infos: product.store_infos.map { |store_info| form_store_info_props(store_info) },
      media: product.media.filter_map { |media| media_props(media) }
    }
  end

  def form_variant_props(variant)
    {
      id: variant.id,
      base_model: variant.base_model?,
      sku: variant.sku,
      size_id: variant.size_id,
      version_id: variant.version_id,
      color_id: variant.color_id,
      purchase_cost: variant.purchase_cost.to_s,
      selling_price: variant.selling_price.to_s,
      weight: variant.weight.to_s,
      deactivated: variant.deactivated?,
      has_sales_or_purchases: variant.persisted? ? variant.has_sales_or_purchases? : false,
      _destroy: false
    }
  end

  def variant_availability_props(product, current_variant: nil)
    return nil unless product

    assignable_variants = product.assignable_variants.includes(:color, :size, :version).to_a
    mode = assignable_variants.any?(&:base_model?) ? "base" : "select"
    variants = assignable_variants

    if current_variant&.product_id == product.id && variants.none? { |variant| variant.id == current_variant.id }
      variants = [*variants, current_variant]
    end

    {
      mode:,
      variants: variants.map { |variant| variant_assignment_option_props(variant) }
    }
  end

  def variant_assignment_option_props(variant)
    {
      value: variant.id,
      label: variant.title.to_s,
      base_model: variant.base_model?
    }
  end

  def form_store_info_props(store_info)
    {
      id: store_info.id,
      store_name: store_info.store_name,
      tag_list: store_info.tag_list.join(", "),
      _destroy: false
    }
  end

  def form_options_props
    {
      franchises: Franchise.order(:title).map { |franchise| select_option(franchise.id, franchise.title) },
      brands: Brand.order(:title).map { |brand| select_option(brand.id, brand.title) },
      shapes: Product.shape_options,
      sizes: Size.order(:value).map { |size| select_option(size.id, size.value) },
      versions: Version.order(:value).map { |version| select_option(version.id, version.value) },
      colors: Color.order(:value).map { |color| select_option(color.id, color.value) },
      suppliers: Supplier.order(:title).map { |supplier| select_option(supplier.id, supplier.title) },
      warehouses: Warehouse.order(:name).map { |warehouse| select_option(warehouse.id, warehouse.name) },
      store_names: StoreInfo.assignable_store_names
    }
  end

  def select_option(value, label)
    {value:, label:}
  end

  def default_purchase_props
    default_warehouse = Warehouse.find_by(is_default: true)
    {
      supplier_id: nil,
      order_reference: "",
      item_price: "",
      amount: "",
      warehouse_id: default_warehouse&.id,
      payment_value: "",
      variant_client_key: nil
    }
  end

  def product_row_class(record_id, selected_id:, hoverable: false, **extra_classes)
    class_names(extra_classes.merge(hoverable:, selected: selected_id == record_id))
  end

  def product_form_errors(product:, purchase: nil)
    errors = []

    product.errors.each do |error|
      next if nested_product_error?(error.attribute)
      next if %i[variants store_infos purchase initial_purchase].include?(error.attribute)

      errors << {label: error.attribute.to_s.humanize, message: error.message}
    end

    product.variants.each do |variant|
      variant.errors.each do |error|
        label = (error.attribute == :base) ? "Variant #{variant.title}" : "Variant #{variant.title} #{error.attribute.to_s.humanize}"
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

  def nested_product_error?(attribute)
    attribute = attribute.to_s
    attribute.include?(".") || attribute.include?("[") || attribute.include?("]")
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
