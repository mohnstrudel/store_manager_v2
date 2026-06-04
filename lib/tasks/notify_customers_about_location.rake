# frozen_string_literal: true

desc "Update customers on their order location"
task notify_customers_about_location: :environment do
  NotifyCustomersAboutOrderLocationJob.perform_later
end
