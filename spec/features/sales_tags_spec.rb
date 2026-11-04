# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sales tags catalog", :js do
  before { sign_in_as_admin }

  let(:filter_field) { "input[aria-label='Filter tags']" }

  def press(key)
    page.driver.browser.keyboard.type(key)
  end

  def save_in_dialog(name:, color: nil, submit: "Create")
    within("dialog") do
      fill_in "Name", with: name
      choose color, allow_label_click: true if color
      click_button submit
    end
  end

  def hold_until_released(release)
    release.pop(timeout: 5) || raise("The held save was never released")
  end

  describe "adding" do
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }

    scenario "opens a modal at its own URL and saves the tag onto the list" do
      visit sales_tags_path
      click_link "Add New Record"

      expect(page).to have_css("dialog h2", text: "New tag")
      expect(page).to have_current_path(new_sales_tag_path)
      expect(page).to have_css("tbody tr", text: "Rush")
      expect(find_field("green", type: "radio", visible: :all)).to be_checked

      save_in_dialog(name: "  VIP   Order ", color: "sky")

      expect(page).to have_no_css("dialog")
      expect(page).to have_current_path(sales_tags_path)
      expect(page).to have_css("tbody tr", text: "VIP Order", count: 1)
      expect(page).to have_content("Sales tag saved")
      expect(SalesTag.order(:id).pluck(:name, :color)).to eq([["Rush", "pink"], ["VIP Order", "sky"]])
    end

    scenario "locks the dialog while a tag is being saved so a newer draft cannot be lost" do
      release = Queue.new
      allow(SalesTag).to receive(:find_or_create_normalized).and_wrap_original do |original, **attributes|
        hold_until_released(release)
        original.call(**attributes)
      end

      visit new_sales_tag_path
      save_in_dialog(name: "VIP Order", color: "sky")

      within("dialog") do
        expect(page).to have_button("Creating…", disabled: true)
        expect(page).to have_button("Cancel", disabled: true)
        expect(page).to have_field("Name", with: "VIP Order", disabled: true)
        expect(page).to have_field("green", type: "radio", disabled: true, visible: :all)
      end

      release << true

      expect(page).to have_no_css("dialog")
      expect(SalesTag.pluck(:name)).to include("VIP Order")
    ensure
      release&.push(true)
    end

    scenario "closes with Back, and Escape or Save replace the history entry so Back never reopens the dialog" do
      visit sales_tags_path

      click_link "Add New Record"
      expect(page).to have_current_path(new_sales_tag_path)
      expect(page).to have_css("dialog h2", text: "New tag")
      page.go_back
      expect(page).to have_current_path(sales_tags_path)
      expect(page).to have_no_css("dialog")

      click_link "Add New Record"
      expect(page).to have_css("dialog")
      press(:escape)
      expect(page).to have_no_css("dialog")
      expect(page).to have_css("a:focus", text: "Add New Record")
      expect(SalesTag.count).to eq(1)
      page.go_back
      expect(page).to have_current_path(sales_tags_path)
      expect(page).to have_no_css("dialog")

      click_link "Add New Record"
      save_in_dialog(name: "VIP Order")
      expect(page).to have_no_css("dialog")
      page.go_back
      expect(page).to have_current_path(sales_tags_path)
      expect(page).to have_no_css("dialog")
    end
  end

  describe "editing" do
    let!(:sale) { create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 2)) }
    let!(:other_sale) { create(:sale, shopify_name: "HSCM#1002", woo_created_at: Time.utc(2024, 1, 1)) }
    let!(:vip) { create(:sales_tag, name: "VIP Order", color: "sky") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }

    before { [sale, other_sale].each { |target| SaleTagging.create!(sale: target, sales_tag: vip) } }

    scenario "rejects a rename onto another tag's name, keeps the draft and the filter, and Cancel leaves both tags alone" do
      visit sales_tags_path
      find(filter_field).set("ru")
      expect(page).to have_css("tbody tr", count: 1)

      within("tbody tr", text: "Rush") { click_link "Edit" }
      save_in_dialog(name: " vip   order ", color: "olive", submit: "Update")

      expect(page).to have_css("dialog", text: "has already been taken")
      expect(page).to have_current_path(edit_sales_tag_path(rush))
      expect(find_field("Name").value).to eq(" vip   order ")
      expect(find_field("olive", type: "radio", visible: :all)).to be_checked
      expect(SalesTag.order(:id).pluck(:name, :color)).to eq([["VIP Order", "sky"], ["Rush", "pink"]])

      click_button "Cancel"

      expect(page).to have_no_css("dialog")
      expect(page).to have_current_path(sales_tags_path)
      expect(find(filter_field).value).to eq("ru")
      expect(page).to have_css("tbody tr", count: 1)
      expect(page).to have_css("tbody tr", text: "Rush")
      expect(SalesTag.order(:id).pluck(:name, :color)).to eq([["VIP Order", "sky"], ["Rush", "pink"]])
    end
  end

  describe "on the sales index" do
    let!(:sale) { create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 2)) }
    let!(:vip) { create(:sales_tag, name: "VIP", color: "sky") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }

    def tags_cell(target)
      find("tbody tr", text: target.shopify_name).find("td:nth-child(3)")
    end

    def open_editor(target)
      within(tags_cell(target)) { click_button "Edit" }
      expect(page).to have_css("dialog h2", text: /\A(Edit|Add) tags\z/)
    end

    def toggle(name)
      find("dialog label.sales_tag_choice", text: name).click
    end

    scenario "saves a selection in the modal and stays on the index" do
      visit sales_path

      open_editor(sale)
      toggle("Rush")
      toggle("VIP")
      click_button "Save"

      expect(page).to have_no_css("dialog")
      within(tags_cell(sale)) { expect(page.all(".sales_tag").map(&:text)).to eq(%w[Rush VIP]) }
      expect(page).to have_current_path(sales_path)
      expect(sale.sales_tags.pluck(:name)).to match_array(%w[Rush VIP])
    end

    scenario "rejects a stale editor, keeps the draft and reloads only on request" do
      SaleTagging.create!(sale:, sales_tag: vip)
      visit sales_path
      open_editor(sale)
      toggle("Rush")

      SaleTagging.where(sale:).delete_all
      SaleTagging.create!(sale:, sales_tag: rush)
      click_button "Save"

      expect(page).to have_content("Tags changed since you opened this editor. Reload tags and try again.")
      expect(page).to have_css("dialog label.sales_tag_choice:has(input:checked)", text: "Rush")
      expect(sale.sales_tags.pluck(:name)).to eq(["Rush"])

      click_button "Reload tags (discards your changes)"

      expect(page).to have_no_css("dialog")
      within(tags_cell(sale)) { expect(page).to have_css(".sales_tag", text: "Rush", count: 1) }
    end
  end

  describe "on the sale page" do
    let!(:sale) { create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 2)) }
    let!(:vip) { create(:sales_tag, name: "VIP", color: "sky") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }

    def toggle(name)
      find("label.sales_tag_choice", text: name).click
    end

    def click_backdrop
      page.driver.browser.mouse.click(x: 5, y: 5)
    end

    def measure(selector, dimension)
      page.evaluate_script("document.querySelector(#{selector.to_json}).getBoundingClientRect().#{dimension}")
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

    scenario "keeps the dialog open and locked while saving" do
      SaleTagging.create!(sale:, sales_tag: vip)
      release = Queue.new
      allow(SaleTagging).to receive(:insert_all!).and_wrap_original do |original, *args, **kwargs|
        hold_until_released(release)
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

    scenario "grows with the window before the tag list scrolls, keeping its height when nothing matches" do
      120.times { |index| create(:sales_tag, name: "Tag #{index}", color: SalesTag::COLORS[index % SalesTag::COLORS.size]) }
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

      find(filter_field).set("Tag 99")
      expect(page).to have_css("dialog label.sales_tag_choice", count: 1)
      one_line_height = measure(".dialog_content", "height")
      find(filter_field).set("zzz")
      expect(page).to have_content("No tags match")
      expect(measure(".dialog_content", "height")).to eq(one_line_height)
    end
  end
end
