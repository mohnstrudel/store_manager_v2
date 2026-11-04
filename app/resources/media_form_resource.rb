# frozen_string_literal: true

class MediaFormResource < MediaResource
  typelize :boolean
  attribute :_destroy do |_media|
    false
  end
end
