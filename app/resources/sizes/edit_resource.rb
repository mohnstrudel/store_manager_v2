# frozen_string_literal: true

class Sizes::EditResource < ApplicationResource
  typelize "Size"
  attribute :size do |page|
    SizeResource.new(page.fetch(:size)).serializable_hash
  end
end
