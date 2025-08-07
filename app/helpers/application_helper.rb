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
      "<mark class='rounded-md py-0.5 px-1.5 text-gray-700 bg-gray-200 text-sm mr-1.5'>#{ratio}</mark>".html_safe
    else
      "<mark class='rounded-md py-0.5 px-1.5 text-yellow-800 bg-yellow-100 text-sm mr-1.5'>#{ratio}</mark>".html_safe
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
    link_to polymorphic_path([:pull, record]), class: "btn-rounded" do
      tag.i(class: "icn") { "📥" } + "Pull"
    end
  end

  def destroy_btn_for(record)
    text = "Destroy this #{record.model_name.human.downcase}"
    css_class = "btn-red w-full h-12 mt-16 btn-rounded"
    confirm_message = "Are you sure?"

    button_to text, polymorphic_path(record), method: :delete, class: css_class, data: {turbo_confirm: confirm_message}
  end
end
