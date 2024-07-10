module ApplicationHelper
  def safe_blank_render(value)
    value.presence || "-"
  end

  def format_time(time)
    time.to_date.to_fs(:long) if time.present?
  end

  def format_date(date)
    date.strftime("%-d %b ’%y")
  end

  def format_money(amount, unit = "")
    number_to_currency(
      amount.to_f,
      delimiter: ".",
      separator: ",",
      format: "%n %u",
      unit:
    )
  end

  def format_zero_values(value)
    (value > 0) ? value : "-"
  end

  def format_sale_status(status)
    status_title = status.titleize

    if Sale.active_status_names.include? status
      "<span class='sale-status--active'>#{status_title}</span>".html_safe
    else
      "<span class='sale-status--inactive'>#{status_title}</span>".html_safe
    end
  end
end
