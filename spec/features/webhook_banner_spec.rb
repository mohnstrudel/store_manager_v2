require "rails_helper"

describe "Webhook banner at Dashboard", js: "true" do
  it "doesn't show the webhook error banner when the webhook is enabled" do
    allow(Config).to receive(:sales_hook_disabled?).and_return(false)
    visit dashboard_index_path

    expect(page).to have_no_selector("#webhook-error")
  end

  it "shows the webhook error banner when the webhook is disabled" do
    allow(Config).to receive(:sales_hook_disabled?).and_return(true)
    visit dashboard_index_path

    expect(page).to have_selector("#webhook-error")
    expect(page).to have_link("Get missing sales from Woo", href: "pull-last-orders")
  end
end
