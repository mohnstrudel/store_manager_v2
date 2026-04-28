# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sales Store Sync" do
  before { sign_in_as_admin }

  scenario "keeps the page clickable after starting a bulk fetch", :js do # rubocop:todo RSpec/MultipleExpectations
    create_list(:sale, 3)
    allow(Config).to receive(:shopify_sales_sync_at).and_return(Time.zone.local(2026, 4, 28, 13, 45))
    allow(Shopify::PullSalesJob).to receive(:perform_later)
    allow(Woo::PullSalesJob).to receive_message_chain(:set, :perform_later)

    visit sales_path
    expect(page).to have_content("Last fetched at 28 April at 13:45")
    click_link "Store Sync"

    click_button "Fetch Everything"

    expect(page).to have_current_path(sales_path, ignore_query: true)
    expect(page).not_to have_css("dialog#sales-index-sync-modal[open]")

    click_link "Store Sync"
    expect(page).to have_css("dialog#sales-index-sync-modal[open]")
  end
end
