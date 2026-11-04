# frozen_string_literal: true

class Franchises::IndexResource < ApplicationResource
  typelize "Array<Franchise>"
  attribute :franchises do |page|
    FranchiseResource.new(page.fetch(:franchises)).serializable_hash
  end
end
