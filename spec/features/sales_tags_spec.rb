# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sales tags catalog", :js do
  before { sign_in_as_admin }
  after { log_out }

  scenario "creates a tag, reuses its identity for case variants and keeps it after reload" do
    visit sales_tags_path

    fill_in "Tag name", with: "VIP Order"
    choose "sky", allow_label_click: true
    click_button "Add tag"

    expect(page).to have_css("tbody tr", text: "VIP Order", count: 1)
    expect(page).to have_field("Tag name", with: "")
    expect(find_field("green", type: "radio", visible: :all)).to be_checked

    fill_in "Tag name", with: " vip   order "
    choose "pink", allow_label_click: true
    click_button "Add tag"

    expect(page).to have_field("Tag name", with: "")
    expect(page).to have_css("tbody tr", count: 1)
    expect(SalesTag.pluck(:name, :color)).to eq([["VIP Order", "sky"]])

    page.refresh

    expect(page).to have_css("tbody tr", text: "VIP Order", count: 1)
  end

  scenario "keeps the draft and shows the error when the name is rejected" do
    visit sales_tags_path

    fill_in "Tag name", with: "x" * 31
    choose "green", allow_label_click: true
    click_button "Add tag"

    expect(page).to have_content("is too long (maximum is 30 characters)")
    expect(find_field("Tag name").value).to eq("x" * 31)
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
    choose "sky", allow_label_click: true
    click_button "Add tag"

    expect(page).to have_field("Tag name", with: "VIP Order", disabled: true)
    expect(page).to have_field("green", type: "radio", disabled: true, visible: :all)
    expect(page).to have_button("Add tag", disabled: true)

    release << true

    expect(page).to have_field("Tag name", with: "", disabled: false)
    expect(SalesTag.pluck(:name, :color)).to eq([["VIP Order", "sky"]])
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
    let!(:vip) { create(:sales_tag, name: "VIP", color: "sky") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }

    def tags_cell(target)
      find("tbody tr", text: target.shopify_name).find("td:nth-child(3)")
    end

    def open_editor(target)
      within(tags_cell(target)) { click_button "Edit" }
      expect(page).to have_css("#sale-#{target.id}-tags-picker")
    end

    def pick(target, name)
      within(tags_cell(target)) { find(".rs__control").click }
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
      expect(page).to have_css(".sales_tag_drafts .sales_tag", text: "Rush")
      expect(page).to have_css(".sales_tag_drafts .sales_tag", text: "VIP")
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
      expect(page).to have_css(".sales_tag_drafts .sales_tag", text: "Rush")
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
        expect(page).to have_css(".sales_tag_drafts .sales_tag", text: "Rush")
        expect(page).to have_no_css(".sales_tags")
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
      within(tags_cell(sale)) { find(".rs__control").click }
      find("#sale-#{sale.id}-tags-picker", visible: :all).send_keys(:enter)
      within(tags_cell(sale)) { find("form").click }

      expect(page).to have_current_path(sales_path)
      expect(page).to have_css("#sale-#{sale.id}-tags-picker", visible: :all)
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

    scenario "searches existing tags by typing and stops offering the ones already selected" do
      visit sales_path

      open_editor(sale)
      picker = find("#sale-#{sale.id}-tags-picker", visible: :all)
      picker.send_keys("vi")
      expect(page).to have_css(".rs__option", text: "VIP")
      expect(page).to have_no_css(".rs__option", text: "Rush")
      find(".rs__option", text: "VIP").click

      within(tags_cell(sale)) { expect(page).to have_css(".sales_tag_drafts .sales_tag", text: "VIP") }
      within(tags_cell(sale)) { find(".rs__control").click }
      expect(page).to have_css(".rs__option", text: "Rush")
      expect(page).to have_no_css(".rs__option", text: "VIP")
      find("#sale-#{sale.id}-tags-picker", visible: :all).send_keys(:escape)
      expect(page).to have_no_css(".rs__option")

      within(tags_cell(sale)) { click_button "Save" }
      within(tags_cell(sale)) { expect(page).to have_css(".sales_tag", text: "VIP") }
      expect(sale.sales_tags.pluck(:name)).to eq(["VIP"])
    end
  end

  describe "on the sale page" do
    let!(:sale) { create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 2)) }
    let!(:vip) { create(:sales_tag, name: "VIP", color: "sky") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }
    let(:filter_field) { "input[aria-label='Filter tags']" }

    def toggle(name)
      find("label.sales_tag_choice", text: name).click
    end

    def press(key)
      page.driver.browser.keyboard.type(key)
    end

    def click_backdrop
      page.driver.browser.mouse.click(x: 5, y: 5)
    end

    def measure(selector, dimension)
      page.evaluate_script("document.querySelector(#{selector.to_json}).getBoundingClientRect().#{dimension}")
    end

    def chip_style(name, property)
      page.evaluate_script(<<~JS)
        (() => {
          const chip = [...document.querySelectorAll("dialog label.sales_tag_choice .sales_tag")]
            .find((element) => element.textContent.trim() === #{name.to_json});
          return getComputedStyle(chip).#{property};
        })()
      JS
    end

    def chip_top(name)
      page.evaluate_script(<<~JS)
        [...document.querySelectorAll("dialog label.sales_tag_choice")]
          .find((element) => element.textContent.trim() === #{name.to_json})
          .getBoundingClientRect().top
      JS
    end

    scenario "saves a selection beneath the heading, keeps it after reload and shows it on the index" do
      visit sale_path(sale)

      click_button "Add tags"
      expect(page).to have_css("dialog h2", text: "Add tags")
      toggle("Rush")
      toggle("VIP")
      click_button "Save"

      expect(page).to have_css("header + div .sales_tag", text: "Rush")
      expect(page).to have_no_css("dialog")
      expect(page).to have_current_path(sale_path(sale))
      expect(sale.sales_tags.pluck(:name)).to match_array(%w[Rush VIP])

      page.refresh

      expect(page.all("header + div .sales_tag").map(&:text)).to eq(%w[Rush VIP])
      expect(page).to have_button("Edit tags")

      visit sales_path

      within("tbody tr", text: "HSCM#1001") { expect(page.all(".sales_tag").map(&:text)).to eq(%w[Rush VIP]) }
    end

    scenario "unchecks a tag, cancels without saving, then saves the removal" do
      SaleTagging.create!(sale:, sales_tag: vip)
      visit sale_path(sale)

      click_button "Edit tags"
      expect(page).to have_css("dialog label.sales_tag_choice:has(input:checked)", text: "VIP")
      toggle("VIP")
      click_button "Cancel"

      expect(page).to have_css("header + div .sales_tag", text: "VIP")
      expect(SaleTagging.where(sale:).count).to eq(1)

      click_button "Edit tags"
      toggle("VIP")
      click_button "Save"

      expect(page).to have_button("Add tags")
      expect(page).to have_no_css("header + div .sales_tag")
      expect(SaleTagging.where(sale:).count).to eq(0)
      expect(SalesTag.where(id: vip.id)).to exist
    end

    scenario "opens from the keyboard, toggles a tag with Space and closes with Escape" do
      visit sale_path(sale)
      page.execute_script("arguments[0].focus()", find_button("Add tags"))

      press(:enter)
      expect(page).to have_css("#{filter_field}:focus")

      press(:tab)
      expect(page).to have_css("label.sales_tag_choice input:focus", visible: :all)
      press(" ")
      expect(page).to have_css("label.sales_tag_choice:has(input:checked)", text: "Rush")

      press(:escape)
      expect(page).to have_no_css("dialog")
      expect(page).to have_css("button:focus", text: "Add tags")
      expect(SaleTagging.count).to eq(0)
    end

    scenario "does not save when Enter is pressed in the filter" do
      visit sale_path(sale)
      click_button "Add tags"
      toggle("Rush")
      find(filter_field).click
      press(:enter)

      expect(page).to have_css("dialog")
      expect(SaleTagging.count).to eq(0)
    end

    scenario "keeps Tab out of the page behind the dialog and returns focus to the control when it closes" do
      visit sale_path(sale)
      click_button "Add tags"
      expect(page).to have_css("#{filter_field}:focus")

      10.times do
        press(:tab)
        expect(page.evaluate_script("document.activeElement === document.body || !!document.activeElement.closest('dialog')")).to be(true)
      end

      click_button "Cancel"

      expect(page).to have_no_css("dialog")
      expect(page).to have_css("button:focus", text: "Add tags")
    end

    scenario "closes with Escape after focus left the form" do
      visit sale_path(sale)
      click_button "Add tags"

      find("dialog h2").click
      press(:escape)

      expect(page).to have_no_css("dialog")
      expect(SaleTagging.count).to eq(0)
    end

    scenario "closes with the cross button" do
      visit sale_path(sale)
      click_button "Add tags"

      find("dialog [aria-label='Close']").click

      expect(page).to have_no_css("dialog")
    end

    scenario "closes from a backdrop click without saving" do
      visit sale_path(sale)
      click_button "Add tags"
      toggle("Rush")

      click_backdrop

      expect(page).to have_no_css("dialog")
      expect(SaleTagging.count).to eq(0)
    end

    scenario "keeps the dialog open and locked while saving" do
      SaleTagging.create!(sale:, sales_tag: vip)
      release = Queue.new
      allow(SaleTagging).to receive(:insert_all!).and_wrap_original do |original, *args, **kwargs|
        release.pop(timeout: 5)
        original.call(*args, **kwargs)
      end
      visit sale_path(sale)
      click_button "Edit tags"
      toggle("Rush")
      click_button "Save"

      within("dialog") do
        expect(page).to have_button("Saving…", disabled: true)
        expect(page).to have_button("Cancel", disabled: true)
        expect(page).to have_css("input[type=checkbox][disabled]", count: 2, visible: :all)
      end
      click_backdrop
      expect(page).to have_css("dialog label.sales_tag_choice:has(input:checked)", text: "Rush")

      release << true

      expect(page).to have_no_css("dialog")
      expect(page).to have_css("header + div .sales_tag", text: "Rush")
      expect(sale.sales_tags.pluck(:name)).to match_array(%w[Rush VIP])
    ensure
      release&.push(true)
    end

    scenario "rejects a stale editor, keeps the draft and reloads only on request" do
      SaleTagging.create!(sale:, sales_tag: vip)
      visit sale_path(sale)
      click_button "Edit tags"
      toggle("Rush")

      SaleTagging.where(sale:).delete_all
      SaleTagging.create!(sale:, sales_tag: rush)
      click_button "Save"

      expect(page).to have_content("Tags changed since you opened this editor. Reload tags and try again.")
      expect(page).to have_css("dialog label.sales_tag_choice:has(input:checked)", text: "Rush")
      expect(sale.sales_tags.pluck(:name)).to eq(["Rush"])

      click_button "Reload tags (discards your changes)"

      expect(page).to have_no_css("dialog")
      expect(page).to have_css("header + div .sales_tag", text: "Rush", count: 1)
    end

    scenario "lets support staff tag the sale" do
      log_out
      sign_in create(:user, :support)
      visit sale_path(sale)

      click_button "Add tags"
      toggle("VIP")
      click_button "Save"

      expect(page).to have_css("header + div .sales_tag", text: "VIP")
      expect(sale.sales_tags.pluck(:name)).to eq(["VIP"])
    end

    scenario "gives each palette color its own line, alphabetical within it" do
      create(:sales_tag, name: "Alpha", color: "sky")
      create(:sales_tag, name: "zebra", color: "green")
      visit sale_path(sale)

      click_button "Add tags"

      expect(page).to have_css("dialog label.sales_tag_choice", count: 4)
      expect(page.all("dialog label.sales_tag_choice").map(&:text)).to eq(%w[zebra Rush Alpha VIP])
      expect(chip_top("zebra")).to be < chip_top("Rush")
      expect(chip_top("Rush")).to be < chip_top("Alpha")
      expect(chip_top("Alpha")).to eq(chip_top("VIP"))
    end

    scenario "centers the dialog title with the close button on one row" do
      visit sale_path(sale)
      click_button "Add tags"
      center = ->(selector) { measure(selector, "top") + (measure(selector, "height") / 2) }

      expect(center.call("dialog h2")).to be_within(1).of(center.call("dialog [aria-label='Close']"))
      expect(measure("dialog [aria-label='Close']", "right")).to be > measure("dialog h2", "right")
    end

    scenario "grows with the window before the tag list scrolls" do
      120.times { |index| create(:sales_tag, name: "Tag #{index}", color: SalesTag::COLORS[index % 8]) }
      scrolls = -> { page.evaluate_script("(() => { const list = document.querySelector('dialog fieldset'); return list.scrollHeight > list.clientHeight; })()") }

      visit sale_path(sale)
      click_button "Add tags"
      expect(page).to have_css("dialog label.sales_tag_choice", count: 122)

      expect(measure("dialog fieldset", "height")).to be > 320
      expect(measure(".dialog_content", "top")).to be >= 0
      expect(measure(".dialog_content", "bottom")).to be <= page.evaluate_script("window.innerHeight")
      expect(scrolls.call).to be(true)

      find(filter_field).set("Tag 9")
      expect(page).to have_no_css("label.sales_tag_choice", text: "Tag 2")
      expect(scrolls.call).to be(false)
    end

    scenario "does not change the dialog height while filtering" do
      visit sale_path(sale)
      click_button "Add tags"
      full_height = measure(".dialog_content", "height")

      find(filter_field).set("ru")
      expect(page).to have_no_css("label.sales_tag_choice", text: "VIP")
      expect(measure(".dialog_content", "height")).to eq(full_height)

      find(filter_field).set("zzz")
      expect(page).to have_content("No tags match")
      expect(measure(".dialog_content", "height")).to eq(full_height)
    end

    scenario "marks a selected tag by a border and a checkmark, never by opacity" do
      visit sale_path(sale)
      click_button "Add tags"
      selected_check = "label.sales_tag_choice:has(input:checked) .sales_tag_check"
      unselected_check = "label.sales_tag_choice:not(:has(input:checked)) .sales_tag_check"

      toggle("Rush")

      expect(page).to have_css("label.sales_tag_choice:has(input:checked)", text: "Rush")
      page.document.synchronize do
        raise Capybara::ExpectationNotMet, "checkmark has not appeared" unless measure(selected_check, "width") >= 12
      end
      expect(measure(unselected_check, "width")).to eq(0)
      expect(chip_style("Rush", "opacity")).to eq(chip_style("VIP", "opacity"))
      expect(chip_style("Rush", "boxShadow")).to include("1.5px")
      expect(chip_style("VIP", "boxShadow")).to eq("none")
    end

    scenario "draws the close button without a background and the actions on a full-width footer" do
      visit sale_path(sale)
      click_button "Add tags"
      style_of = ->(selector, property) { page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).#{property}") }
      transparent = "rgba(0, 0, 0, 0)"

      expect(style_of.call("dialog [aria-label='Close']", "backgroundColor")).to eq(transparent)
      expect(style_of.call(".dialog_footer", "backgroundColor")).not_to eq(transparent)
      expect(measure(".dialog_footer", "left")).to eq(measure(".dialog_content", "left"))
      expect(measure(".dialog_footer", "width")).to eq(measure(".dialog_content", "width"))
      expect(page).to have_css(".dialog_footer button[type=submit]", text: "Save")
      expect(page).to have_css(".dialog_footer button", text: "Cancel")
      expect(style_of.call(".dialog_footer button[type=button]", "backgroundColor")).to eq("rgb(255, 255, 255)")
    end

    scenario "puts Save and Cancel at the left edge of the form" do
      visit sale_path(sale)
      click_button "Add tags"

      expect(measure("dialog button[type=submit]", "left")).to eq(measure(filter_field, "left"))
      expect(page).to have_css("dialog button[type=submit] + button", text: "Cancel")
    end
  end
end
