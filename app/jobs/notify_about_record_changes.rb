# frozen_string_literal: true
class NotifyAboutRecordChanges < ApplicationJob
  queue_as :default

  retry_on Timeout::Error, HTTParty::Error, wait: :polynomially_longer

  WEBHOOK_URL = ENV["SLACK_WEBHOOK_URL"]

  def perform(record)
    return if WEBHOOK_URL.nil? || record.nil?

    @record = record
    @audit = record.audits.last

    begin
      HTTParty.post(
        WEBHOOK_URL,
        headers: {"Content-Type" => "application/json"},
        body: {text: message}.to_json
      )
    rescue => e
      Rails.logger.error("Failed to send Slack notification: #{e.message}")
    end
  end

  private

  def message
    case @audit.action
    when "update"
      "#{@record.class.name} #{@record.id} was updated:\n" + changes
    when "destroy"
      "#{@record.class.name} was destroyed:\n" + record_details
    end
  end

  def record_details
    @record
      .attributes
      .map { |k, v| " - #{k.titleize}: #{v}" }
      .join("\n")
  end

  def changes
    @audit
      .audited_changes
      .map { |k, v| " - #{k.titleize}: #{v.first} -> #{v.last}" }
      .join("\n")
  end
end
