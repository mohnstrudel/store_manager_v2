# frozen_string_literal: true

class Versions::FormResource < ApplicationResource
  typelize "VersionsFormVersion"
  attribute :version do |page|
    Versions::FormVersionResource.new(page.fetch(:version)).serializable_hash
  end
end
