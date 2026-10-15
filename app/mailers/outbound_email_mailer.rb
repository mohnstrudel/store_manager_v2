# frozen_string_literal: true

class OutboundEmailMailer < ApplicationMailer
  def stored(outbound_email)
    mail(
      from: outbound_email.sender,
      to: outbound_email.recipient,
      subject: outbound_email.subject,
      body: outbound_email.body,
      content_type: "text/plain"
    )
  end
end
