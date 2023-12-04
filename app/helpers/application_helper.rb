module ApplicationHelper
  def safe_blank_render(value)
    value.presence || "-"
  end

  def format_time(time)
    time.to_fs(:long) if time.present?
  end

  def format_money(amount)
    number_to_currency(amount.to_f, delimiter: "", unit: "")
  end

  def format_zero_values(value)
    (value > 0) ? value : "-"
  end
end
