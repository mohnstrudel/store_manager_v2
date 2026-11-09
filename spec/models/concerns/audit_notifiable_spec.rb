# frozen_string_literal: true

require "rails_helper"

describe AuditNotifiable do
  before do
    stub_const("DummyModel", Class.new(ApplicationRecord) do
      self.table_name = "customers"
      audited
      include AuditNotifiable
    end)
    allow(Rails.env).to receive_messages(production?: true, staging?: false)
  end

  let(:dummy) { DummyModel.new(email: "test@example.com") }

  it "enqueues NotifyAboutRecordChanges after a commit that wrote an audit" do
    expect {
      dummy.save!
    }.to have_enqueued_job(NotifyAboutRecordChanges).with(dummy)
  end

  it "enqueues again when a later update writes an audit" do
    dummy.save!

    expect {
      dummy.update!(email: "changed@example.com")
    }.to have_enqueued_job(NotifyAboutRecordChanges).with(dummy)
  end

  it "does not enqueue when a touch commits without an audit" do
    dummy.save!

    expect {
      dummy.touch
    }.not_to have_enqueued_job(NotifyAboutRecordChanges)
  end

  it "does not enqueue when a save changes nothing" do
    dummy.save!

    expect {
      dummy.save!
    }.not_to have_enqueued_job(NotifyAboutRecordChanges)
  end

  it "does not enqueue when auditing is disabled" do
    expect {
      DummyModel.without_auditing { dummy.save! }
    }.not_to have_enqueued_job(NotifyAboutRecordChanges)
  end

  it "does not enqueue job in staging" do
    allow(Rails.env).to receive(:staging?).and_return(true)
    expect {
      dummy.save!
    }.not_to have_enqueued_job(NotifyAboutRecordChanges)
  end
end
