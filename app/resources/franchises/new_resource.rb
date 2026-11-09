# frozen_string_literal: true

class Franchises::NewResource < ApplicationResource
  typelize({title: :string})
  attribute :franchise do |page|
    franchise = page.fetch(:franchise)

    {title: franchise.title.to_s}
  end
end
