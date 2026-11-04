# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Signing in", :js do
  it "signs in through the form and lands on the signed-in page" do
    user = create(:user, email_address: "reader@example.com", password: "secret-passphrase")

    visit sign_in_path
    fill_in "Email address", with: "reader@example.com"
    fill_in "Password", with: "secret-passphrase"
    click_on "Sign in"

    expect(page).to have_current_path(noop_path)
    expect(page).to have_text("Access Required")
    expect(page).to have_button("Log Out")
    expect(user.sessions.count).to eq(1)
  end
end
