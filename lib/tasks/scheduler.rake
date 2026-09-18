# frozen_string_literal: true

namespace :scheduler do
  task supervise_sales_webhook: :environment do
    Woo::SuperviseSalesWebhookJob.perform_later
  end
end
