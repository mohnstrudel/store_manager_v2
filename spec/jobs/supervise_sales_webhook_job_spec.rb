require "rails_helper"

RSpec.describe SuperviseSalesWebhookJob do
  let(:job) {
    described_class.new
  }
  let(:sale) {
    create(:sale, woo_id: 123)
  }

  it "does nothing if the webhook is disabled" do
    allow(Config).to receive(:sales_hook_disabled?).and_return(true)
    expect(job.perform).to be_nil
  end

  it "does nothing if the webhook is enabled and sales are in sync" do
    allow(Config).to receive(:sales_hook_disabled?).and_return(false)
    allow(job).to receive(:api_get_latest).and_return({id: sale.woo_id})
    expect(job.perform).to be_nil
  end

  it "disables the webhook is sales are not in sync" do
    allow(Config).to receive(:sales_hook_disabled?).and_return(false)
    allow(job).to receive(:api_get_latest).and_return({id: 666})
    expect(job.perform).to be true
  end
end
