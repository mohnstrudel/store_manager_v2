# frozen_string_literal: true

require "rails_helper"

describe HasAuditNotifications do
  before do
    stub_const("DummyModel", Class.new(ApplicationRecord) do
      self.table_name = "customers"
      include HasAuditNotifications

      def self.auditing_enabled
        true
      end
    end)
    allow(Rails.env).to receive_messages(production?: true, staging?: false)
  end

  let(:dummy) { DummyModel.new(email: "test@example.com") }

  it "enqueues NotifyAboutRecordChanges after commit if audited and in production" do
    expect {
      dummy.save!
    }.to have_enqueued_job(NotifyAboutRecordChanges).with(dummy)
  end

  it "does not enqueue job if not audited" do
    allow(DummyModel).to receive(:auditing_enabled).and_return(false)
    expect {
      dummy.save!
    }.not_to have_enqueued_job(NotifyAboutRecordChanges)
  end

  it "does not enqueue job in staging" do
    allow(Rails.env).to receive(:staging?).and_return(true)
    expect {
      dummy.save!
    }.not_to have_enqueued_job(NotifyAboutRecordChanges)
  end
end
