# frozen_string_literal: true

namespace :scheduler do
  task supervise_sales_webhook: :environment do
    Woo::SuperviseSalesWebhookJob.perform_later
  end

  task dispatch_outbound_emails: :environment do
    OutboundEmail.pending.ids.each { |id| OutboundEmailDeliveryJob.perform_later(id) }
  end
end
