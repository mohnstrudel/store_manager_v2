# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  include Sidekiq::Status::Worker

  retry_on ActiveRecord::Deadlocked
  discard_on ActiveJob::DeserializationError
end
