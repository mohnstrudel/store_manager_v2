# frozen_string_literal: true

class Versions::IndexResource < ApplicationResource
  typelize "Array<Version>"
  attribute :versions do |page|
    VersionResource.new(page.fetch(:versions)).serializable_hash
  end
end
