# frozen_string_literal: true

class OutboundEmails::DetailResource < OutboundEmailResource
  typelize :string
  attribute :sender, &:sender

  typelize :string
  attribute :body, &:body

  attributes :attempts, :last_attempt_at, :last_error

  typelize :string, nullable: true
  attribute :product_thumb_url do |_email|
    sale_item = params.fetch(:sale_item)
    thumb_url(sale_item.product) if sale_item
  end
end
