namespace :scheduler do
  # These tasks are called by the Heroku scheduler add-on
  # https://devcenter.heroku.com/articles/scheduler

  task supervise_sales_webhook: :environment do
    SuperviseSalesWebhookJob.perform_later
  end
end
