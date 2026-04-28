# frozen_string_literal: true

module UiHelper
  def form_hint(text)
    tag.p text, class: "text-gray-600 dark:text-gray-500"
  end

  def slim_select_html_options(action: nil, **attributes)
    data = attributes.delete(:data) || {}
    data[:controller] = [data[:controller], "slim-select"].compact.join(" ").strip
    data[:action] = [data[:action], action].compact.join(" ").strip if action.present?

    {
      class: class_names("select", attributes.delete(:class)),
      data:
    }.merge(attributes)
  end

  def form_submit_for(model, form)
    render partial: "_shared/form-submit", locals: {model:, form:}
  end

  def edit_btn_for(record)
    render "_shared/action_edit", route: edit_polymorphic_path(record)
  end

  def fetch_btn_for(record, path: nil)
    link_to(path || polymorphic_path([record, :pull]), class: "btn-rounded", data: {"turbo-prefetch": "false", turbo_method: :post}) do
      heroicon("chevron-double-down", variant: "mini") + "Fetch"
    end
  end

  def destroy_btn_for(record)
    text = "Destroy this #{record.model_name.human.downcase}"

    button_to text,
      polymorphic_path(record),
      method: :delete,
      class: "btn-red w-full h-12 mt-16 btn-rounded",
      data: {turbo_confirm: "Are you sure?"}
  end

  def copy_to_clipboard(text:, css: nil, label: "Copy")
    render partial: "_shared/copy_to_clipboard", locals: {text:, css:, label:}
  end

  def tooltip(text, star_class: nil)
    content_tag(:span, class: "group relative") do
      content_tag(:span, "*", class: "text-yellow-600 ml-2 text-2xl/2 #{star_class}") +
        content_tag(:span, text, class: "cursor-text no-events absolute z-20 top-0 left-0 opacity-0 pointer-events-none transition-opacity duration-150 flex group-hover:opacity-100 group-hover:pointer-events-auto rounded-lg bg-yellow-100 dark:bg-yellow-800 border border-yellow-800/10 pt-4 pr-5 pb-5 pl-3 w-64 text-yellow-800 dark:text-yellow-100 text-sm text-pretty")
    end
  end

  def thumb_url(model)
    return if model.media.blank?

    first_media = model.media.min_by(&:position)
    return unless first_media&.image&.attached?

    url_for(first_media.image.representation(:thumb))
  end
end
