# frozen_string_literal: true
require "rails_helper"

RSpec.describe WebhookController do
  # rubocop:disable RSpec/MultipleMemoizedHelpers
  describe "#verify_webhook" do
    let(:invalid_signature) { "invalid_signature" }
    let(:payload) { "test_payload" }
    let(:secret) { "my_secret" }
    let(:valid_signature) do
      Base64.strict_encode64(OpenSSL::HMAC.digest("sha256", secret, payload))
    end

    before do
      request.headers["x-wc-webhook-signature"] = valid_signature
      allow(request).to receive(:body).and_return(StringIO.new(payload))
    end

    it "returns true when the signature is valid" do
      expect(subject.send(:verify_webhook, secret)).to be_truthy # rubocop:todo RSpec/NamedSubject
    end

    it "returns false when the signature is invalid" do
      request.headers["x-wc-webhook-signature"] = invalid_signature
      expect(subject.send(:verify_webhook, secret)).to be_falsy # rubocop:todo RSpec/NamedSubject
    end
  end
  # rubocop:enable RSpec/MultipleMemoizedHelpers
end
