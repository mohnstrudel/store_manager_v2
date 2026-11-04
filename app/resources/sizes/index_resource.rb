# frozen_string_literal: true

class Sizes::IndexResource < ApplicationResource
  typelize "Array<Size>"
  attribute :sizes do |page|
    SizeResource.new(page.fetch(:sizes)).serializable_hash
  end
end
