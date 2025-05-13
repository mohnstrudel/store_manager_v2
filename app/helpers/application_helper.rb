module ApplicationHelper
  def safe_blank_render(value)
    value.presence || "-"
  end

  def format_date(date)
    date&.strftime("%-d. %B %Y")
  end

  def format_money(amount, unit = "")
    if amount.presence
      number_to_currency(
        amount.to_f,
        delimiter: ".",
        separator: ",",
        format: "%n %u",
        precision: 0,
        unit:
      ).strip
    end
  end

  def format_zero_values(value)
    (value.to_i > 0) ? value : "-"
  end

  def format_show_page_title(record)
    return record.title.titleize if record.respond_to?(:title)
    return record.name.titleize if record.respond_to?(:name)
    record.value.titleize if record.respond_to?(:value)
  end

  def format_item_size(item)
    length = item.length ? "ℓ#{item.length}" : nil
    width = item.width ? "w#{item.width}" : nil
    height = item.height ? "h#{item.height}" : nil
    [length, width, height].compact.join(" × ")
  end

  def thumb_url(model)
    if model.images.present?
      url_for(model.images.first.representation(:thumb))
    end
  end

  def format_purchased_sold_ratio(purchased, sold)
    ratio = "#{purchased} / #{sold}"

    if purchased >= sold
      "<mark class='smaller muted'>#{ratio}</mark>".html_safe
    else
      "<mark class='smaller'>#{ratio}</mark>".html_safe
    end
  end
end
