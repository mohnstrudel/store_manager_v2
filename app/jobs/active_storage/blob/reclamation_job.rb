# frozen_string_literal: true

class ActiveStorage::Blob::ReclamationJob < ApplicationJob
  queue_as :default

  def perform(cutoff:)
    ActiveStorage::Blob::Reclamation.apply!(cutoff: Time.iso8601(cutoff))
  end
end
