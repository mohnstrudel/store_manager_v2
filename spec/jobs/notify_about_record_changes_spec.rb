# frozen_string_literal: true
require "rails_helper"

describe NotifyAboutRecordChanges do
  include ActiveJob::TestHelper

  let(:webhook_url) { "https://hooks.slack.com/services/test/webhook" }
  let(:product) { create(:product, title: "Test Product") }
  let(:audit) { instance_double(Audited::Audit) }
  let(:audits_relation) { instance_double(ActiveRecord::Relation, last: audit) }

  before do
    stub_const("#{described_class}::WEBHOOK_URL", webhook_url)
    allow(HTTParty).to receive(:post)
    allow(product).to receive(:audits).and_return(audits_relation)
    allow(audit).to receive_messages(
      action: "update",
      audited_changes: {"title" => ["Old Title", "New Title"]}
    )
  end

  describe "#perform" do
    context "when webhook URL is not configured" do
      before do
        stub_const("#{described_class}::WEBHOOK_URL", nil)
      end

      it "does not send notification" do
        described_class.perform_now(product)

        expect(HTTParty).not_to have_received(:post)
      end
    end

    context "when record is nil" do
      it "does not send notification" do
        described_class.perform_now(nil)

        expect(HTTParty).not_to have_received(:post)
      end
    end

    context "when webhook URL and record are present" do
      let(:expected_payload) do
        {
          headers: {"Content-Type" => "application/json"},
          body: {text: "Product #{product.id} was updated:\n - Title: Old Title -> New Title"}.to_json
        }
      end

      it "sends POST request to Slack webhook" do
        described_class.perform_now(product)

        expect(HTTParty).to have_received(:post).with(webhook_url, expected_payload)
      end
    end

    context "when HTTParty raises an error" do
      before do
        allow(HTTParty).to receive(:post).and_raise(StandardError.new("Network error"))
        allow(Rails.logger).to receive(:error)
      end

      it "logs the error" do
        described_class.perform_now(product)

        expect(Rails.logger).to have_received(:error).with("Failed to send Slack notification: Network error")
      end

      it "does not re-raise the error" do
        expect { described_class.perform_now(product) }.not_to raise_error
      end
    end
  end

  describe "#message" do
    let(:job) { described_class.new }

    before do
      job.instance_variable_set(:@record, product)
      job.instance_variable_set(:@audit, audit)
    end

    context "when audit action is update" do
      before do
        allow(audit).to receive_messages(
          action: "update",
          audited_changes: {"title" => ["Old Title", "New Title"]}
        )
        allow(product).to receive(:id).and_return(1)
      end

      it "returns update message with changes" do
        expected_message = "Product 1 was updated:\n - Title: Old Title -> New Title"

        expect(job.send(:message)).to eq(expected_message)
      end
    end

    context "when audit action is destroy" do
      before do
        allow(audit).to receive(:action).and_return("destroy")
        allow(product).to receive_messages(id: 1, attributes: {"id" => 1, "title" => "Test Product"})
      end

      it "returns destroy message with record details" do
        expected_message = "Product was destroyed:\n - Id: 1\n - Title: Test Product"

        expect(job.send(:message)).to eq(expected_message)
      end
    end
  end

  describe "#record_details" do
    let(:job) { described_class.new }

    before do
      job.instance_variable_set(:@record, product)
      allow(product).to receive(:attributes).and_return({
        "id" => 1,
        "title" => "Test Product",
        "created_at" => "2024-01-01"
      })
    end

    it "formats record attributes with titleized keys" do
      expected_details = " - Id: 1\n - Title: Test Product\n - Created At: 2024-01-01"

      expect(job.send(:record_details)).to eq(expected_details)
    end
  end

  describe "#changes" do
    let(:job) { described_class.new }

    before do
      job.instance_variable_set(:@audit, audit)
      allow(audit).to receive(:audited_changes).and_return({
        "title" => ["Old Title", "New Title"],
        "price" => [100, 150]
      })
    end

    it "formats audit changes with before and after values" do
      expected_changes = " - Title: Old Title -> New Title\n - Price: 100 -> 150"

      expect(job.send(:changes)).to eq(expected_changes)
    end
  end

  describe "job enqueueing" do
    it "enqueues the job" do
      expect {
        described_class.perform_later(product)
      }.to have_enqueued_job(described_class).with(product)
    end

    it "uses default queue" do
      expect(described_class.queue_name).to eq("default")
    end
  end
end
