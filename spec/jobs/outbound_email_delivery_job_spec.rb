# frozen_string_literal: true

require "rails_helper"

RSpec.describe OutboundEmailDeliveryJob do
  let(:transport) do
    Class.new do
      class << self
        attr_accessor :before_delivery

        def deliveries = (@deliveries ||= [])
      end

      def initialize(_settings)
      end

      def deliver!(mail)
        self.class.before_delivery&.call(mail)
        self.class.deliveries << mail
      end
    end
  end

  around do |example|
    original_method = ActionMailer::Base.delivery_method
    original_perform = ActionMailer::Base.perform_deliveries
    ActionMailer::Base.delivery_method = transport
    example.run
  ensure
    ActionMailer::Base.delivery_method = original_method
    ActionMailer::Base.perform_deliveries = original_perform
  end

  describe "#perform" do
    it "delivers the stored recipient, sender, subject and text regardless of later customer or warehouse edits" do
      warehouse = create(:warehouse, external_name_en: "Shipped")
      customer = create(:customer, email: "buyer@example.com")
      sale_item = create(:sale_item, sale: create(:sale, customer:))
      purchase_item = create(:purchase_item, warehouse:, sale_item:)
      email = create(:outbound_email,
        purchase_item_id: purchase_item.id, sale_item_id: sale_item.id, warehouse_id: warehouse.id,
        recipient: "buyer@example.com", sender: "HandsomeCake Goodies <store@handsomecake.com>",
        subject: "Stored subject", body: "Hallo Buyer,\r\n\r\nStored body Grüße")
      customer.update!(email: "changed@example.com", first_name: "Changed")
      warehouse.update!(external_name_en: "Changed")

      described_class.perform_now(email.id)

      mail = transport.deliveries.sole
      expect(mail.to).to eq(["buyer@example.com"])
      expect(mail.from).to eq(["store@handsomecake.com"])
      expect(mail[:from].display_names).to eq(["HandsomeCake Goodies"])
      expect(mail.subject).to eq("Stored subject")
      expect(mail.mime_type).to eq("text/plain")
      expect(mail.body.decoded.force_encoding("UTF-8")).to eq("Hallo Buyer,\r\n\r\nStored body Grüße")
    end

    it "marks accepted only after the transport returns" do
      email = create(:outbound_email)
      state_during_transport = nil
      transport.before_delivery = ->(_mail) { state_during_transport = OutboundEmail.find(email.id).state }

      described_class.perform_now(email.id)

      expect(state_during_transport).to eq("pending")
      expect(email.reload).to have_attributes(state: "accepted", attempts: 1, last_error: nil)
      expect(email.accepted_at).to be_present
    end

    it "does not hand off an accepted row again" do
      email = create(:outbound_email)

      2.times { described_class.perform_now(email.id) }

      expect(transport.deliveries.size).to eq(1)
    end

    it "never hands off an assumed baseline" do
      baseline = create(:outbound_email, :assumed_baseline)

      described_class.perform_now(baseline.id)

      expect(transport.deliveries).to be_empty
      expect(baseline.reload).to have_attributes(state: "assumed_baseline", attempts: 0, accepted_at: nil)
    end

    it "keeps one pending row with attempt metadata when the transport fails, and accepts it on retry" do
      email = create(:outbound_email)
      transport.before_delivery = ->(_mail) { raise Net::OpenTimeout, "mailtrap unreachable" }

      expect { described_class.perform_now(email.id) }.to raise_error(Net::OpenTimeout)

      expect(email.reload).to have_attributes(state: "pending", attempts: 1, accepted_at: nil)
      expect(email.last_error).to include("Net::OpenTimeout", "mailtrap unreachable")
      expect(email.last_attempt_at).to be_present

      transport.before_delivery = nil
      described_class.perform_now(email.id)

      expect(OutboundEmail.count).to eq(1)
      expect(email.reload).to have_attributes(state: "accepted", attempts: 2, last_error: nil)
      expect(transport.deliveries.size).to eq(1)
    end

    it "marks simulated without a handoff or acceptance time when deliveries are disabled" do
      ActionMailer::Base.perform_deliveries = false
      email = create(:outbound_email)

      described_class.perform_now(email.id)

      expect(transport.deliveries).to be_empty
      expect(email.reload).to have_attributes(state: "simulated", attempts: 1, accepted_at: nil)
    end
  end

  describe "overlapping workers" do
    self.use_transactional_tests = false

    it "hands off once when two workers overlap on the same row" do
      email = create(:outbound_email)
      inside_transport = Queue.new
      release_transport = Queue.new
      transport.before_delivery = lambda { |_mail|
        inside_transport << true
        release_transport.pop(timeout: 5)
      }

      first = Thread.new { run_job_in_own_connection(email.id) }
      inside_transport.pop
      second = Thread.new { run_job_in_own_connection(email.id) }
      wait_until_a_session_waits_on_a_lock
      2.times { release_transport << true }
      [first, second].each(&:value)

      expect(transport.deliveries.size).to eq(1)
    ensure
      email&.destroy!
    end

    def run_job_in_own_connection(email_id)
      ActiveRecord::Base.connection_pool.with_connection { described_class.perform_now(email_id) }
    end

    def wait_until_a_session_waits_on_a_lock
      Timeout.timeout(5) do
        sleep 0.01 until ActiveRecord::Base.connection.select_value(<<~SQL.squish).positive?
          SELECT count(*) FROM pg_stat_activity
          WHERE datname = current_database() AND wait_event_type = 'Lock'
        SQL
      end
    end
  end
end
