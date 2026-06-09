# frozen_string_literal: true

module VersionHelper
  def version_form_props(version)
    {
      version: version_props(version)
    }
  end

  def version_props(version)
    {
      id: version.id,
      value: version.value.to_s,
      created_at: formatted_timestamp(version.created_at),
      updated_at: formatted_timestamp(version.updated_at)
    }
  end
end
