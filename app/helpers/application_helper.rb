module ApplicationHelper
  def safe_blank_render(value)
    value.presence || "-"
  end

  def format_time(time)
    time.to_fs(:long)
  end
end
