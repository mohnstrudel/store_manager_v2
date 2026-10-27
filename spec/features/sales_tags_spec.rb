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
    expect(find_field("yellow", type: "radio", visible: :all)).to be_checked

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
    expect(page).to have_field("yellow", type: "radio", disabled: true, visible: :all)
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

  describe "on the sales index" do
    let!(:sale) { create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 2)) }
    let!(:other_sale) { create(:sale, shopify_name: "HSCM#1002", woo_created_at: Time.utc(2024, 1, 1)) }
    let!(:vip) { create(:sales_tag, name: "VIP", color: "blue") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "red") }

    def tags_cell(target)
      find("tbody tr", text: target.shopify_name).find("td:nth-child(3)")
    end

    def open_editor(target)
      within(tags_cell(target)) { click_button "Edit" }
      expect(page).to have_css("#sale-#{target.id}-tags-picker")
    end

    def pick(target, name)
      find("#sale-#{target.id}-tags-picker").click
      find(".rs__option", text: name).click
    end

    scenario "saves a selection, reopens with it and keeps it after reload" do
      visit sales_path

      open_editor(sale)
      pick(sale, "Rush")
      pick(sale, "VIP")
      within(tags_cell(sale)) { click_button "Save" }

      within(tags_cell(sale)) do
        expect(page).to have_css(".sales_tag", text: "Rush")
        expect(page).to have_css(".sales_tag", text: "VIP")
        expect(page).to have_no_button("Save")
      end
      expect(page).to have_current_path(sales_path)
      expect(sale.sales_tags.pluck(:name)).to match_array(%w[Rush VIP])

      page.refresh

      within(tags_cell(sale)) { expect(page.all(".sales_tag").map(&:text)).to eq(%w[Rush VIP]) }
      open_editor(sale)
      expect(page).to have_css(".rs__multi-value__label", text: "Rush")
      expect(page).to have_css(".rs__multi-value__label", text: "VIP")
    end

    scenario "removing a tag from one sale keeps it on the other" do
      [sale, other_sale].each { |target| SaleTagging.create!(sale: target, sales_tag: vip) }
      visit sales_path

      open_editor(sale)
      within(tags_cell(sale)) { find("[aria-label='Remove VIP']").click }
      within(tags_cell(sale)) { click_button "Save" }

      within(tags_cell(sale)) { expect(page).to have_no_css(".sales_tag") }
      within(tags_cell(other_sale)) { expect(page).to have_css(".sales_tag", text: "VIP") }
      expect(SaleTagging.where(sales_tag: vip).pluck(:sale_id)).to eq([other_sale.id])
    end

    scenario "cancels without saving" do
      visit sales_path

      open_editor(sale)
      pick(sale, "Rush")
      within(tags_cell(sale)) { click_button "Cancel" }

      within(tags_cell(sale)) { expect(page).to have_no_css(".sales_tag") }
      expect(SaleTagging.count).to eq(0)
    end

    scenario "rejects a stale editor, keeps the draft and reloads only on request" do
      SaleTagging.create!(sale:, sales_tag: vip)
      visit sales_path
      open_editor(sale)
      pick(sale, "Rush")

      SaleTagging.where(sale:).delete_all
      SaleTagging.create!(sale:, sales_tag: rush)
      within(tags_cell(sale)) { click_button "Save" }

      expect(page).to have_content("Tags changed since you opened this editor. Reload tags and try again.")
      expect(page).to have_css(".rs__multi-value__label", text: "Rush")
      expect(sale.sales_tags.pluck(:name)).to eq(["Rush"])

      click_button "Reload tags (discards your changes)"

      within(tags_cell(sale)) do
        expect(page).to have_no_button("Save")
        expect(page).to have_css(".sales_tag", text: "Rush", count: 1)
      end
    end

    scenario "keeps the saved badges and locks the editor while saving" do
      SaleTagging.create!(sale:, sales_tag: vip)
      release = Queue.new
      allow(SaleTagging).to receive(:insert_all!).and_wrap_original do |original, *args, **kwargs|
        release.pop(timeout: 5)
        original.call(*args, **kwargs)
      end
      visit sales_path
      open_editor(sale)
      pick(sale, "Rush")
      within(tags_cell(sale)) { click_button "Save" }

      within(tags_cell(sale)) do
        expect(page).to have_button("Saving…", disabled: true)
        expect(page).to have_button("Cancel", disabled: true)
        expect(page).to have_css(".rs__multi-value__label", text: "Rush")
        expect(page).to have_no_css(".sales_tag")
      end

      release << true

      within(tags_cell(sale)) { expect(page).to have_css(".sales_tag", text: "Rush") }
      expect(sale.sales_tags.pluck(:name)).to match_array(%w[Rush VIP])
    ensure
      release&.push(true)
    end

    scenario "does not open the sale from clicks or keys inside the editor" do
      visit sales_path

      open_editor(sale)
      find("#sale-#{sale.id}-tags-picker").click
      find("#sale-#{sale.id}-tags-picker").send_keys(:enter)
      within(tags_cell(sale)) { find("form").click }

      expect(page).to have_current_path(sales_path)
      expect(page).to have_css("#sale-#{sale.id}-tags-picker")
    end

    scenario "closes the menu with the first Escape and cancels with the second" do
      visit sales_path

      open_editor(sale)
      find("#sale-#{sale.id}-tags-picker").click
      expect(page).to have_css(".rs__option", text: "Rush")

      find("#sale-#{sale.id}-tags-picker").send_keys(:escape)
      expect(page).to have_no_css(".rs__option")
      expect(page).to have_css("#sale-#{sale.id}-tags-picker")

      find("#sale-#{sale.id}-tags-picker").send_keys(:escape)
      expect(page).to have_no_css("#sale-#{sale.id}-tags-picker")
    end

    scenario "lets support staff tag sales" do
      log_out
      sign_in create(:user, :support)
      SaleTagging.create!(sale:, sales_tag: vip)
      visit sales_path

      open_editor(sale)
      pick(sale, "Rush")
      within(tags_cell(sale)) { click_button "Save" }

      within(tags_cell(sale)) { expect(page).to have_css(".sales_tag", text: "Rush") }
    end
  end
end
