require "rails_helper"

RSpec.describe SuperviseSalesWebhookJob do
  let(:job) {
    described_class.new
  }
  let(:sale) {
    create(:sale, woo_id: 123, status: Sale.active_status_names.first)
  }

  it "does nothing if the webhook is disabled" do
    Config.disable_sales_hook

    job.perform

    expect(Config.sales_hook_disabled?).to be true
  end

  it "does nothing if the webhook is enabled and sales are in sync" do
    Config.enable_sales_hook

    allow(job).to receive(:api_get_latest_orders).and_return([{
      id: sale.woo_id,
      status: sale.status
    }])
    job.perform

    expect(Config.sales_hook_disabled?).to be false
  end

  it "change the webhook status to disabled if sales and orders are not in sync" do
    Config.enable_sales_hook

    allow(job).to receive(:api_get_latest_orders).and_return([{
      id: 666,
      status: sale.status
    }])
    job.perform

    expect(Config.sales_hook_disabled?).to be true
  end
end
