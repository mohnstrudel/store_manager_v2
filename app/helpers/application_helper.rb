# frozen_string_literal: true

module ApplicationHelper
  def safe_blank_render(value)
    value.presence || "-"
  end

  def format_date(date)
    date&.strftime("%-d. %b ’%y")
  end

  def format_money(amount, unit = "")
    if amount.presence
      number_to_currency(
        amount.to_f,
        delimiter: " ",
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
    return if model.media.blank?

    first_media = model.media.min_by(&:position)
    return unless first_media&.image&.attached?

    url_for(first_media.image.representation(:thumb))
  end

  def format_purchased_sold_ratio(purchased, sold)
    ratio = "#{purchased} / #{sold}"

    if purchased >= sold
      content_tag(:mark, ratio, class: "mark-gray mr-1.5")
    else
      content_tag(:mark, ratio, class: "mr-1.5")
    end
  end

  def form_submit_for(model, form)
    render partial: "_shared/form-submit", locals: {model:, form:}
  end

  def back_btn
    render partial: "_shared/action_go_back"
  end

  def edit_btn_for(record)
    render "_shared/action_edit", route: edit_polymorphic_path(record)
  end

  def pull_btn_for(record)
    link_to polymorphic_path([:pull, record]), class: "btn-rounded", data: {"turbo-prefetch": "false"} do
      tag.i(class: "icn") { "📥" } + "Pull"
    end
  end

  def destroy_btn_for(record)
    text = "Destroy this #{record.model_name.human.downcase}"
    css_class = "btn-red w-full h-12 mt-16 btn-rounded"
    confirm_message = "Are you sure?"

    button_to text, polymorphic_path(record), method: :delete, class: css_class, data: {turbo_confirm: confirm_message}
  end

  def copy_to_clipboard(text:, css: nil)
    render partial: "_shared/copy_to_clipboard", locals: {text:, css:}
  end

  def tooltip(text, star_class: nil)
    content_tag(:span, class: "group relative") do
      content_tag(:span, "*", class: "text-yellow-600 ml-2 text-2xl/2 #{star_class}") +
        content_tag(:span, text, class: "cursor-text no-events absolute z-20 top-0 left-0 opacity-0 pointer-events-none transition-opacity duration-150 flex group-hover:opacity-100 group-hover:pointer-events-auto rounded-lg bg-yellow-100 dark:bg-yellow-800 border border-yellow-800/10 pt-4 pr-5 pb-5 pl-3 w-64 text-yellow-800 dark:text-yellow-100 text-sm text-pretty")
    end
  end
end
