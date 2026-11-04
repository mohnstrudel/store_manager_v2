# frozen_string_literal: true

class SalesTagResource < ApplicationResource
  typelize_from SalesTag

  attributes :id, :name

  typelize '"green" | "pink" | "sky" | "violet" | "olive"'
  attribute :color, &:color
end
