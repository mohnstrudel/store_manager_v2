module HasAuditNotifications
  extend ActiveSupport::Concern

  included do
    after_commit :send_audits_to_slack, if: :model_is_audited?

    private

    def send_audits_to_slack
      if !Rails.env.staging? && Rails.env.production?
        NotifyAboutRecordChanges.perform_later(self)
      end
    end

    def model_is_audited?
      self.class.respond_to?(:auditing_enabled) && self.class.auditing_enabled
    end
  end
end
