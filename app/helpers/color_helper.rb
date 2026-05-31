# frozen_string_literal: true

module ColorHelper
  def color_form_props(color)
    {
      color: color_props(color)
    }
  end

  def color_props(color)
    {
      id: color.id,
      value: color.value.to_s,
      created_at: formatted_timestamp(color.created_at),
      updated_at: formatted_timestamp(color.updated_at)
    }
  end
end
