# frozen_string_literal: true

require "rails_helper"

RSpec.describe Woo::SuperviseSalesWebhookJob do
  let(:job) {
    described_class.new
  }
  let(:sale) {
    create(:sale, woo_store_id: "123", status: Sale.active_status_names.first)
  }

  before do
    allow(Sentry).to receive(:capture_message)
  end

  it "does nothing if the webhook is disabled" do
    Config.disable_sales_hook

    job.perform

    expect(Config.sales_hook_disabled?).to be true
  end

  it "does nothing if the webhook is enabled and sales are in sync" do
    Config.enable_sales_hook

    allow(job).to receive(:api_get_latest_orders).and_return([{
      id: sale.woo_store_id,
      status: sale.status
    }])
    job.perform

    expect(Config.sales_hook_disabled?).to be false
    expect(job).to have_received(:api_get_latest_orders)
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

  it "captures context and keeps the webhook enabled when latest orders are unavailable" do
    Config.enable_sales_hook

    allow(job).to receive(:api_get_latest_orders).and_return(nil)

    job.perform

    expect(Config.sales_hook_disabled?).to be false
    expect(Sentry).to have_received(:capture_message).with(
      "Woo supervise sales webhook could not load latest orders",
      level: :error,
      tags: {job: "Woo::SuperviseSalesWebhookJob", integration: "woo"}
    )
  end

  it "captures context and keeps the webhook enabled when Woo returns no active orders" do
    Config.enable_sales_hook

    allow(job).to receive(:api_get_latest_orders).and_return([{
      id: sale.woo_store_id,
      status: "cancelled"
    }])

    job.perform

    expect(Config.sales_hook_disabled?).to be false
    expect(Sentry).to have_received(:capture_message).with(
      "Woo supervise sales webhook found no active orders",
      level: :warning,
      tags: {job: "Woo::SuperviseSalesWebhookJob", integration: "woo"},
      extra: {
        active_status_names: Sale.active_status_names,
        returned_statuses: ["cancelled"],
        orders_checked: 1
      }
    )
  end
end
