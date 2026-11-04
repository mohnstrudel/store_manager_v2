# frozen_string_literal: true

module AuditNotifiable
  extend ActiveSupport::Concern

  included do
    after_commit :send_audits_to_slack, if: :audit_written?
    after_rollback :forget_written_audit
  end

  private

  def send_audits_to_slack
    forget_written_audit
    if !Rails.env.staging? && Rails.env.production?
      NotifyAboutRecordChanges.perform_later(self)
    end
  end

  def forget_written_audit
    @audit_written = false
  end

  def audit_written?
    @audit_written
  end

  def after_audit
    @audit_written = true
  end
end
