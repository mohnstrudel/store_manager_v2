# frozen_string_literal: true

class Franchises::EditResource < ApplicationResource
  typelize "Franchise"
  attribute :franchise do |page|
    FranchiseResource.new(page.fetch(:franchise)).serializable_hash
  end
end
