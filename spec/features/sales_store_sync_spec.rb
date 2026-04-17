# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sales Store Sync" do
  before { sign_in_as_admin }

  scenario "keeps the page clickable after starting a bulk pull", :js do # rubocop:todo RSpec/MultipleExpectations
    create_list(:sale, 3)
    allow(Shopify::PullSalesJob).to receive(:perform_later)
    allow(Woo::PullSalesJob).to receive_message_chain(:set, :perform_later)

    visit sales_path
    click_link "Store Sync"

    click_button "Pull Last 50 Sales"

    expect(page).to have_current_path(sales_path, ignore_query: true)
    expect(page).not_to have_css("dialog#sales-index-sync-modal[open]")

    click_link "Store Sync"
    expect(page).to have_css("dialog#sales-index-sync-modal[open]")
  end
end
