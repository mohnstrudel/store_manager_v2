# frozen_string_literal: true

class OutboundEmailDeliveryJob < ApplicationJob
  queue_as :default

  def perform(outbound_email_id)
    OutboundEmail.find(outbound_email_id).deliver!
  end
end
