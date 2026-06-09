# frozen_string_literal: true

module SizeHelper
  def size_form_props(size)
    {
      size: size_props(size)
    }
  end

  def size_props(size)
    {
      id: size.id,
      value: size.value.to_s,
      created_at: formatted_timestamp(size.created_at),
      updated_at: formatted_timestamp(size.updated_at)
    }
  end
end
