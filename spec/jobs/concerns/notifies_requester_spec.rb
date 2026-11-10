# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotifiesRequester do
  let(:user) { create(:user) }
  let(:job_class) do
    Class.new(ApplicationJob) do
      include NotifiesRequester

      def perform(requested_by: nil)
        raise "boom"
      end
    end
  end

  context "when the job does not say how to describe its failure" do
    it "raises an error that says what to implement, in place of a script error that would skip later callbacks" do
      expect { job_class.perform_now(requested_by: user) }
        .to raise_error(NoMethodError, /must implement #failure_notification/)
    end

    it "still runs the callbacks registered after it" do
      ran = []
      job_class.after_discard { |_job, _error| ran << true }

      expect { job_class.perform_now(requested_by: user) }.to raise_error(NoMethodError)

      expect(ran).to eq([true])
    end

    it "does not ask for a description when nobody requested the job" do
      expect { job_class.perform_now }.to raise_error(RuntimeError, "boom")
    end
  end

  context "when the job describes its failure" do
    before do
      job_class.define_method(:failure_notification) { |error| {message: "Failed: #{error.message}"} }
    end

    it "alerts the requester with the description of the error that ended the job" do
      expect { expect { job_class.perform_now(requested_by: user) }.to raise_error("boom") }
        .to have_broadcasted_to(user).from_channel(NotificationsChannel)
        .with(kind: "alert", message: "Failed: boom")
    end

    it "stays quiet when Sidekiq interrupts the job for a shutdown, because it runs the job again afterwards" do
      job_class.define_method(:perform) { |requested_by: nil| raise Sidekiq::Shutdown }

      expect { expect { job_class.perform_now(requested_by: user) }.to raise_error(Sidekiq::Shutdown) }
        .not_to have_broadcasted_to(user).from_channel(NotificationsChannel)
    end

    context "when Sidekiq runs the job again after an unhandled error" do
      let(:cache) { ActiveSupport::Cache::MemoryStore.new }
      let(:payload) { job_class.new(requested_by: user).serialize }

      before do
        stub_const("RequesterAlertProbeJob", job_class)
        allow(Rails).to receive(:cache).and_return(cache)
      end

      def run_again(times)
        times.times { expect { job_class.execute(payload) }.to raise_error("boom") }
      end

      it "alerts the requester once however many times the same job fails" do
        expect { run_again(3) }
          .to have_broadcasted_to(user).from_channel(NotificationsChannel)
          .with(kind: "alert", message: "Failed: boom").exactly(:once)
      end

      it "alerts the requester of each job that fails" do
        other_payload = job_class.new(requested_by: user).serialize

        expect {
          expect { job_class.execute(payload) }.to raise_error("boom")
          expect { job_class.execute(other_payload) }.to raise_error("boom")
        }.to have_broadcasted_to(user).from_channel(NotificationsChannel).exactly(:twice)
      end

      it "alerts again when the alert was forgotten" do
        run_again(1)
        cache.clear

        expect { run_again(1) }.to have_broadcasted_to(user).from_channel(NotificationsChannel).exactly(:once)
      end

      it "keeps raising for a run nobody requested, so Sidekiq retries it, without remembering anything" do
        anonymous_payload = job_class.new.serialize
        allow(cache).to receive(:write).and_call_original

        2.times { expect { job_class.execute(anonymous_payload) }.to raise_error("boom") }

        expect(cache).not_to have_received(:write)
      end
    end
  end
end
