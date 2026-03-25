# frozen_string_literal: true

require "rails_helper"
require "stringio"

RSpec.describe Webhooks::OrderUpdatesController, type: :controller do
  describe "#verify_webhook" do
    let(:secret) { "test_secret" }
    let(:payload) { "{\"test\":\"data\"}" }
    let(:valid_signature) { Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, payload)) }
    let(:invalid_signature) { "invalid_signature" }

    before do
      allow(request).to receive(:body).and_return(StringIO.new(payload))
    end

    context "when signature is valid" do
      before do
        request.headers["x-wc-webhook-signature"] = valid_signature
      end

      it "returns true" do
        expect(subject.send(:verify_webhook, secret)).to be_truthy # rubocop:todo RSpec/NamedSubject
      end
    end

    context "when signature is invalid" do
      it "returns false" do
        request.headers["x-wc-webhook-signature"] = invalid_signature
        expect(subject.send(:verify_webhook, secret)).to be_falsy # rubocop:todo RSpec/NamedSubject
      end
    end
  end
end
