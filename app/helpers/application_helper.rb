module ApplicationHelper
  def safe_blank_render(value)
    value.presence || "-"
  end

  def format_time(time)
    time.to_fs(:long) if time.present?
  end

  def format_date(date)
    date.strftime("%-d %b %Y")
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
end
