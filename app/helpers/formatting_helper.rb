# frozen_string_literal: true

module FormattingHelper
  def safe_blank_render(value)
    value.presence || "-"
  end

  def format_date(date)
    date&.strftime("%-d. %b ’%y")
  end

  def format_datetime(date)
    date&.strftime("%-d. %b ’%y %H:%M")
  end

  def format_last_fetched_at(time)
    return if time.blank?

    "Last fetched at #{time.in_time_zone.strftime("%-d %B at %H:%M")}"
  end

  def format_money(amount, unit = "")
    return unless amount.presence

    number_to_currency(
      amount.to_f,
      delimiter: " ",
      separator: ",",
      format: "%n %u",
      precision: 0,
      unit:
    ).strip
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

  def format_purchased_sold_ratio(purchased, sold)
    purchased_count = purchased.to_i
    sold_count = sold.to_i
    ratio = "#{purchased} / #{sold}"

    if purchased_count >= sold_count
      content_tag(:mark, ratio, class: "mark-gray mr-1.5")
    else
      content_tag(:mark, ratio, class: "mr-1.5")
    end
  end
end
