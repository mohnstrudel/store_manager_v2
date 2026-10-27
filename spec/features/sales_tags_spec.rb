# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sales tags catalog", :js do
  before { sign_in_as_admin }
  after { log_out }

  scenario "creates a tag, reuses its identity for case variants and keeps it after reload" do
    visit sales_tags_path

    fill_in "Tag name", with: "VIP Order"
    choose "blue", allow_label_click: true
    click_button "Add tag"

    expect(page).to have_css("tbody tr", text: "VIP Order", count: 1)
    expect(page).to have_field("Tag name", with: "")
    expect(find_field("gray", type: "radio", visible: :all)).to be_checked

    fill_in "Tag name", with: " vip   order "
    choose "red", allow_label_click: true
    click_button "Add tag"

    expect(page).to have_field("Tag name", with: "")
    expect(page).to have_css("tbody tr", count: 1)
    expect(SalesTag.pluck(:name, :color)).to eq([["VIP Order", "blue"]])

    page.refresh

    expect(page).to have_css("tbody tr", text: "VIP Order", count: 1)
  end

  scenario "keeps the draft and shows the error when the name is rejected" do
    visit sales_tags_path

    fill_in "Tag name", with: "one two three"
    choose "green", allow_label_click: true
    click_button "Add tag"

    expect(page).to have_content("must be one or two words")
    expect(find_field("Tag name").value).to eq("one two three")
    expect(find_field("green", type: "radio", visible: :all)).to be_checked
    expect(SalesTag.count).to eq(0)
  end

  scenario "locks the form while a tag is being saved so a newer draft cannot be lost" do
    release = Queue.new
    allow(SalesTag).to receive(:find_or_create_normalized!).and_wrap_original do |original, **attributes|
      release.pop(timeout: 5)
      original.call(**attributes)
    end

    visit sales_tags_path
    fill_in "Tag name", with: "VIP Order"
    choose "blue", allow_label_click: true
    click_button "Add tag"

    expect(page).to have_field("Tag name", with: "VIP Order", disabled: true)
    expect(page).to have_field("gray", type: "radio", disabled: true, visible: :all)
    expect(page).to have_button("Add tag", disabled: true)

    release << true

    expect(page).to have_field("Tag name", with: "", disabled: false)
    expect(SalesTag.pluck(:name, :color)).to eq([["VIP Order", "blue"]])
  ensure
    release&.push(true)
  end

  scenario "lays out the add form on one row on desktop" do
    visit sales_tags_path
    expect(page).to have_field("Tag name")

    centers = page.evaluate_script(<<~JS)
      ["#sales_tag_name", ".sales_tag_choices", "form button[type='submit']"].map((selector) => {
        const rect = document.querySelector(selector).getBoundingClientRect();
        return rect.top + rect.height / 2;
      })
    JS

    expect(centers.max - centers.min).to be < 2
  end

  scenario "searches by name, keeps the search across creation and survives reload" do
    create(:sales_tag, name: "VIP Order")
    create(:sales_tag, name: "Rush")

    visit sales_tags_path
    fill_in "q", with: "vip"
    click_button "Search"

    expect(page).to have_current_path(sales_tags_path(q: "vip"))
    expect(page).to have_css("tbody tr", text: "VIP Order", count: 1)
    expect(page).to have_no_css("tbody tr", text: "Rush")

    fill_in "Tag name", with: "VIP Rush"
    click_button "Add tag"

    expect(page).to have_css("tbody tr", count: 2)
    expect(page).to have_current_path(sales_tags_path(q: "vip"))

    page.refresh

    expect(page).to have_css("tbody tr", count: 2)
  end

  scenario "does not let support staff open the catalog" do
    log_out
    sign_in create(:user, :support)

    visit sales_tags_path

    expect(page).to have_current_path(noop_path)
    expect(page).to have_no_field("Tag name")
  end
end
