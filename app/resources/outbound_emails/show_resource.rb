# frozen_string_literal: true

class OutboundEmails::ShowResource < ApplicationResource
  typelize "OutboundEmailsDetail"
  attribute :outbound_email do |page|
    OutboundEmails::DetailResource.new(page.fetch(:outbound_email), params: page.slice(:sale_item)).serializable_hash
  end
end
