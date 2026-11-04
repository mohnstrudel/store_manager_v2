# frozen_string_literal: true

class MediaResource < ApplicationResource
  typelize_from Media

  attributes :id, :alt, :position

  typelize :string
  attribute :preview_url do |media|
    representation_path(media, :preview)
  end

  typelize :string
  attribute :thumb_url do |media|
    representation_path(media, :thumb)
  end

  def self.attached(media)
    new(media.select { |medium| medium.image.attached? }).serializable_hash
  end

  def representation_path(media, variant)
    route_for(ActiveStorage.resolve_model_to_route, media.image.representation(variant), only_path: true)
  end
end
