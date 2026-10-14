# frozen_string_literal: true

require "rails_helper"
require "rake"

RSpec.describe "scheduler:dispatch_outbound_emails" do
  include ActiveJob::TestHelper

  before do
    Rails.application.load_tasks unless Rake::Task.task_defined?("scheduler:dispatch_outbound_emails")
    ActionMailer::Base.deliveries.clear
  end

  def sweep
    task = Rake::Task["scheduler:dispatch_outbound_emails"]
    task.reenable
    task.invoke
  end

  def enqueued_email_ids
    enqueued_jobs.select { |job| job[:job] == OutboundEmailDeliveryJob }.pluck(:args).flatten
  end

  it "queues pending rows, including one whose initial push was lost, and ignores every other state" do
    missed_push = create(:outbound_email)
    create(:outbound_email, state: "accepted", accepted_at: Time.current)
    create(:outbound_email, state: "simulated")
    create(:outbound_email, :assumed_baseline)
    clear_enqueued_jobs

    sweep

    expect(enqueued_email_ids).to eq([missed_push.id])
  end

  it "recovers a row after its initial enqueue raises" do
    allow(Rails.logger).to receive(:error)
    allow(OutboundEmailDeliveryJob).to receive(:perform_later).and_raise("queue offline")
    email = create(:outbound_email)
    allow(OutboundEmailDeliveryJob).to receive(:perform_later).and_call_original

    sweep
    expect(enqueued_email_ids).to eq([email.id])

    perform_enqueued_jobs
    expect(email.reload.state).to eq("accepted")
    expect(ActionMailer::Base.deliveries.size).to eq(1)
  end

  it "makes one successful handoff per row however often the sweep queues it" do
    email = create(:outbound_email)
    clear_enqueued_jobs

    2.times { sweep }
    perform_enqueued_jobs

    expect(ActionMailer::Base.deliveries.size).to eq(1)
    expect(email.reload.state).to eq("accepted")

    clear_enqueued_jobs
    sweep

    expect(enqueued_email_ids).to be_empty
  end
end
