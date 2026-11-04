# frozen_string_literal: true

class OutboundEmailResource < ApplicationResource
  typelize_from OutboundEmail

  attributes :id

  typelize :string
  attribute :recipient, &:recipient

  attributes :recipient_name

  typelize :string
  attribute :subject, &:subject

  attributes :product_title

  typelize :string, enum: %w[pending accepted simulated]
  attribute :state, &:state

  attributes :created_at, :accepted_at
end
