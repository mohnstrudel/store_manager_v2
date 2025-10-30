require "rails_helper"

describe "Webhook banner at Dashboard", js: "true" do
  before { sign_in_as_admin }
  after { log_out }

  it "doesn't show the webhook error banner when the webhook is enabled" do
    allow(Config).to receive(:sales_hook_disabled?).and_return(false)
    visit root_path

    expect(page).to have_no_selector("#webhook-error")
  end

  it "shows the webhook error banner when the webhook is disabled" do
    allow(Config).to receive(:sales_hook_disabled?).and_return(true)
    visit root_path

    expect(page).to have_selector("#webhook-error")
    expect(page).to have_link("Confirm Woo Webhook Active", href: "pull-last-orders")
  end
end
