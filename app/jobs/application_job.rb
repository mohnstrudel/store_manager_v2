class ApplicationJob < ActiveJob::Base
  unless Rails.env.production?
    include SuckerPunch::Job
  end

  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError
end
