# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Sales tags catalog", :js do
  before { sign_in_as_admin }
  after { log_out }

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

  describe "adding" do
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }

    scenario "opens a modal at its own URL, saves, reuses an existing identity and keeps the tag after reload" do
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

      click_link "Add New Record"
      save_in_dialog(name: "vip order", color: "olive")

      expect(page).to have_no_css("dialog")
      expect(page).to have_css("tbody tr", count: 2)
      expect(SalesTag.order(:id).pluck(:name, :color)).to eq([["Rush", "pink"], ["VIP Order", "sky"]])

      page.refresh

      expect(page).to have_css("tbody tr", text: "VIP Order", count: 1)
    end

    scenario "spaces the color chips below their legend like the name input below its label" do
      visit new_sales_tag_path
      expect(page).to have_css("dialog h2", text: "New tag")
      gap = lambda do |above, below|
        page.evaluate_script("document.querySelector(#{below.to_json}).getBoundingClientRect().top - document.querySelector(#{above.to_json}).getBoundingClientRect().bottom")
      end

      name_gap = gap.call("dialog label[for]", "dialog input:not([type=radio])")

      expect(name_gap).to be > 0
      expect(gap.call("dialog legend", "dialog .sales_tag_choices")).to eq(name_gap)
    end

    scenario "leaves the same space under the color chips as the tag dialog leaves under its chips" do
      sale = create(:sale)
      SalesTag::COLORS.each { |color| 3.times { |index| create(:sales_tag, name: "#{color} #{index}", color:) } }
      space_below_chips = lambda do
        page.evaluate_script(<<~JS)
          (() => {
            const fieldset = document.querySelector("dialog fieldset");
            const footer = document.querySelector(".dialog_footer");
            return footer.getBoundingClientRect().top - fieldset.getBoundingClientRect().bottom + parseFloat(getComputedStyle(fieldset).paddingBottom);
          })()
        JS
      end

      visit sale_path(sale)
      click_button "Add tags"
      expect(page).to have_css("dialog h2", text: "Add tags")
      tag_dialog_space = space_below_chips.call

      visit new_sales_tag_path
      expect(page).to have_css("dialog h2", text: "New tag")

      expect(space_below_chips.call).to eq(tag_dialog_space)
    end

    scenario "opens the same modal from its URL over the list, also after a reload" do
      visit new_sales_tag_path

      expect(page).to have_css("dialog h2", text: "New tag")
      expect(page).to have_css("tbody tr", text: "Rush")

      page.refresh

      expect(page).to have_css("dialog h2", text: "New tag")
      expect(find_field("Name").value).to eq("")
      expect(find_field("green", type: "radio", visible: :all)).to be_checked
    end

    scenario "offers the colors as large chips like the tag dialog, checkmarking the selected one" do
      visit new_sales_tag_path
      chip = ->(color) { "dialog label.sales_tag_choice:has(input[value=#{color}])" }
      width = ->(selector) { page.evaluate_script("document.querySelector(#{selector.to_json}).getBoundingClientRect().width") }
      check_width = ->(color) { width.call("#{chip.call(color)} .sales_tag_check") }
      wait_for_check = lambda do |color|
        page.document.synchronize do
          raise Capybara::ExpectationNotMet, "checkmark of #{color} has not appeared" unless check_width.call(color) >= 12
        end
      end

      expect(page).to have_css("#{chip.call("green")}:has(input:checked)", text: "Green")
      wait_for_check.call("green")
      expect(check_width.call("sky")).to eq(0)

      find(chip.call("sky")).click

      expect(page).to have_css("#{chip.call("sky")}:has(input:checked)")
      wait_for_check.call("sky")
      page.document.synchronize do
        raise Capybara::ExpectationNotMet, "checkmark of green has not gone" unless check_width.call("green").zero?
      end

      style = page.evaluate_script(<<~JS)
        (() => {
          const chip = getComputedStyle(document.querySelector("dialog .sales_tag_choice .sales_tag"));
          return {fontSize: chip.fontSize, paddingLeft: chip.paddingLeft};
        })()
      JS
      expect(style).to eq("fontSize" => "14px", "paddingLeft" => "10px")
    end

    scenario "keeps the dialog open with the draft and the error when the name is rejected" do
      visit new_sales_tag_path

      save_in_dialog(name: "x" * 31, color: "pink")

      expect(page).to have_css("dialog", text: "is too long (maximum is 30 characters)")
      expect(page).to have_current_path(new_sales_tag_path)
      expect(find_field("Name").value).to eq("x" * 31)
      expect(find_field("pink", type: "radio", visible: :all)).to be_checked
      expect(SalesTag.count).to eq(1)
    end

    scenario "locks the dialog while a tag is being saved so a newer draft cannot be lost" do
      release = Queue.new
      allow(SalesTag).to receive(:find_or_create_normalized!).and_wrap_original do |original, **attributes|
        release.pop(timeout: 5)
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

    scenario "closes with Escape back onto the list and returns focus to the Add New Record link" do
      visit sales_tags_path
      click_link "Add New Record"
      expect(page).to have_css("dialog h2", text: "New tag")

      press(:escape)

      expect(page).to have_no_css("dialog")
      expect(page).to have_current_path(sales_tags_path)
      expect(page).to have_css("a:focus", text: "Add New Record")
      expect(SalesTag.count).to eq(1)
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

    scenario "invites adding the first tag when the catalog is empty" do
      SalesTag.delete_all
      visit sales_tags_path

      click_link "Add your first sales tag"

      expect(page).to have_css("dialog h2", text: "New tag")
      expect(page).to have_current_path(new_sales_tag_path)
    end
  end

  scenario "filters the list by name as you type without changing the URL" do
    create(:sales_tag, name: "VIP Order")
    create(:sales_tag, name: "vip club")
    create(:sales_tag, name: "Rush")
    visit sales_tags_path

    find(filter_field).set(" VIP ")

    expect(page).to have_css("tbody tr", count: 2)
    expect(page).to have_no_css("tbody tr", text: "Rush")
    expect(page).to have_current_path(sales_tags_path)

    find(filter_field).set("zzz")

    expect(page).to have_content("No tags match “zzz”.")

    find(filter_field).set("")

    expect(page).to have_css("tbody tr", count: 3)
  end

  describe "editing" do
    let!(:sale) { create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 2)) }
    let!(:other_sale) { create(:sale, shopify_name: "HSCM#1002", woo_created_at: Time.utc(2024, 1, 1)) }
    let!(:vip) { create(:sales_tag, name: "VIP Order", color: "sky") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }

    before { [sale, other_sale].each { |target| SaleTagging.create!(sale: target, sales_tag: vip) } }

    scenario "opens from the Edit link at its own URL with the saved values, also after a reload" do
      visit sales_tags_path

      within("tbody tr", text: "VIP Order") { click_link "Edit" }

      expect(page).to have_css("dialog h2", text: "Edit tag")
      expect(page).to have_current_path(edit_sales_tag_path(vip))
      expect(find_field("Name").value).to eq("VIP Order")
      expect(find_field("sky", type: "radio", visible: :all)).to be_checked

      page.refresh

      expect(page).to have_css("dialog h2", text: "Edit tag")
      expect(find_field("Name").value).to eq("VIP Order")
    end

    scenario "updates a tag used by two sales everywhere without touching the sales" do
      stamps = -> { Sale.where(id: [sale, other_sale]).order(:id).pluck(:id, :updated_at) }
      before_stamps = stamps.call
      visit sales_tags_path

      within("tbody tr", text: "VIP Order") { click_link "Edit" }
      save_in_dialog(name: "  VIP   Client ", color: "olive", submit: "Update")

      expect(page).to have_no_css("dialog")
      expect(page).to have_current_path(sales_tags_path)
      expect(page).to have_css("tbody tr", text: "VIP Client")
      expect(vip.reload).to have_attributes(name: "VIP Client", color: "olive")
      expect(stamps.call).to eq(before_stamps)

      visit sales_path

      [sale, other_sale].each do |target|
        within("tbody tr", text: target.shopify_name) { expect(page).to have_css(".sales_tag[data-color='olive']", text: "VIP Client") }
      end

      visit sale_path(sale)

      expect(page).to have_css("header + div .sales_tag[data-color='olive']", text: "VIP Client")
      click_button "Edit tags"
      expect(page).to have_css("dialog label.sales_tag_choice:has(input:checked)", text: "VIP Client")
    end

    scenario "rejects a rename onto another tag's name, keeps the draft, and Cancel leaves both tags alone" do
      visit sales_tags_path

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
      expect(page).to have_css("tbody tr", text: "Rush")
      expect(SalesTag.order(:id).pluck(:name, :color)).to eq([["VIP Order", "sky"], ["Rush", "pink"]])
    end

    scenario "keeps the filter text when a dialog opens and closes over the list" do
      visit sales_tags_path
      find(filter_field).set("vip")
      expect(page).to have_css("tbody tr", count: 1)

      within("tbody tr", text: "VIP Order") { click_link "Edit" }
      expect(page).to have_css("dialog h2", text: "Edit tag")
      click_button "Cancel"

      expect(page).to have_no_css("dialog")
      expect(find(filter_field).value).to eq("vip")
      expect(page).to have_css("tbody tr", count: 1)
    end
  end

  describe "details" do
    let!(:vip) { create(:sales_tag, name: "VIP Order", color: "sky") }
    let!(:sale) { create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 2)) }
    let!(:older_sale) { create(:sale, shopify_name: "HSCM#1002", woo_created_at: Time.utc(2024, 1, 1)) }
    let!(:product) { create(:product).tap { |record| create(:media, :for_product, mediaable: record) } }
    let!(:item) { create(:sale_item, sale:, product:, variant: nil) }

    before { [sale, older_sale].each { |target| SaleTagging.create!(sale: target, sales_tag: vip) } }

    def rows
      page.all("ol[aria-label='Sales with this tag'] > li")
    end

    def sale_links
      page.all("ol[aria-label='Sales with this tag'] a").map(&:text)
    end

    def style_of(selector, property)
      page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).#{property}")
    end

    scenario "opens from a row click at its own URL with a numbered list of sales, also after a reload" do
      visit sales_tags_path

      find("tbody tr", text: "VIP Order").click

      expect(page).to have_css("dialog h2 .sales_tag_title[data-color='sky']", text: "VIP Order")
      expect(page).to have_current_path(sales_tag_path(vip))
      expect(sale_links).to eq([
        "HSCM#1001, Michele Pomarico, italy_mp@web.de, #{item.title}",
        "HSCM#1002, Michele Pomarico, italy_mp@web.de"
      ])
      expect(rows.map { |row| row.text[/\A\d+\./] }).to eq(%w[1. 2.])

      page.refresh

      expect(page).to have_css("dialog h2", text: "VIP Order")
      expect(sale_links.size).to eq(2)
    end

    scenario "shows a 25 wide 3:4 preview slot for every sale, a placeholder when it has no usable picture" do
      visit sales_tag_path(vip)
      expect(page).to have_css("ol[aria-label='Sales with this tag'] > li", count: 2)
      size = lambda do |selector|
        page.evaluate_script("(() => { const r = document.querySelector(#{selector.to_json}).getBoundingClientRect(); return [Math.round(r.width), Math.round(r.height)]; })()")
      end

      expect(size.call("ol li:first-child img, ol li:first-child [role=img]")).to eq([100, 133])
      expect(size.call("ol li:last-child [role=img]")).to eq([100, 133])
    end

    scenario "gives the heading the tag's own background in the heading font" do
      visit sales_tag_path(vip)
      expect(page).to have_css("dialog h2 .sales_tag_title")

      expect(style_of("dialog h2 .sales_tag_title", "backgroundColor")).not_to eq("rgba(0, 0, 0, 0)")
      expect(style_of("dialog h2 .sales_tag_title", "fontSize")).to eq(style_of("dialog h2", "fontSize"))
      expect(style_of("dialog h2 .sales_tag_title", "fontWeight")).to eq(style_of("dialog h2", "fontWeight"))
    end

    scenario "follows a sale link to the sale page" do
      visit sales_tag_path(vip)

      click_link "HSCM#1002, Michele Pomarico, italy_mp@web.de"

      expect(page).to have_current_path(sale_path(older_sale))
    end

    scenario "closes with Escape onto the list, and Back never reopens it" do
      visit sales_tags_path
      find("tbody tr", text: "VIP Order").click
      expect(page).to have_css("dialog h2", text: "VIP Order")

      press(:escape)

      expect(page).to have_no_css("dialog")
      expect(page).to have_current_path(sales_tags_path)
      page.go_back
      expect(page).to have_current_path(sales_tags_path)
      expect(page).to have_no_css("dialog")
    end

    scenario "keeps the Edit link on the row for the edit dialog" do
      visit sales_tags_path

      within("tbody tr", text: "VIP Order") { click_link "Edit" }

      expect(page).to have_css("dialog h2", text: "Edit tag")
      expect(page).to have_current_path(edit_sales_tag_path(vip))
    end
  end

  scenario "does not let support staff open the catalog or its dialogs" do
    log_out
    sign_in create(:user, :support)
    tag = create(:sales_tag, name: "Existing")

    [sales_tags_path, new_sales_tag_path, edit_sales_tag_path(tag)].each do |path|
      visit path

      expect(page).to have_current_path(noop_path)
      expect(page).to have_no_css("dialog")
    end
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
      expect(page).to have_css("dialog h2", text: /\A(Edit|Add) tags\z/)
    end

    def toggle(name)
      find("dialog label.sales_tag_choice", text: name).click
    end

    scenario "saves a selection in the modal, stays on the index and keeps it after reload" do
      visit sales_path

      open_editor(sale)
      toggle("Rush")
      toggle("VIP")
      click_button "Save"

      expect(page).to have_no_css("dialog")
      within(tags_cell(sale)) { expect(page.all(".sales_tag").map(&:text)).to eq(%w[Rush VIP]) }
      expect(page).to have_current_path(sales_path)
      expect(sale.sales_tags.pluck(:name)).to match_array(%w[Rush VIP])

      page.refresh

      within(tags_cell(sale)) { expect(page.all(".sales_tag").map(&:text)).to eq(%w[Rush VIP]) }
      open_editor(sale)
      expect(page).to have_css("dialog label.sales_tag_choice:has(input:checked)", count: 2)
    end

    scenario "removing a tag from one sale keeps it on the other" do
      [sale, other_sale].each { |target| SaleTagging.create!(sale: target, sales_tag: vip) }
      visit sales_path

      open_editor(sale)
      toggle("VIP")
      click_button "Save"

      expect(page).to have_no_css("dialog")
      within(tags_cell(sale)) { expect(page).to have_no_css(".sales_tag") }
      within(tags_cell(other_sale)) { expect(page).to have_css(".sales_tag", text: "VIP") }
      expect(SaleTagging.where(sales_tag: vip).pluck(:sale_id)).to eq([other_sale.id])
    end

    scenario "cancels without saving" do
      visit sales_path

      open_editor(sale)
      toggle("Rush")
      click_button "Cancel"

      expect(page).to have_no_css("dialog")
      within(tags_cell(sale)) { expect(page).to have_no_css(".sales_tag") }
      expect(SaleTagging.count).to eq(0)
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

    scenario "keeps the saved badges and locks the modal while saving" do
      SaleTagging.create!(sale:, sales_tag: vip)
      release = Queue.new
      allow(SaleTagging).to receive(:insert_all!).and_wrap_original do |original, *args, **kwargs|
        release.pop(timeout: 5)
        original.call(*args, **kwargs)
      end
      visit sales_path
      open_editor(sale)
      toggle("Rush")
      click_button "Save"

      within("dialog") do
        expect(page).to have_button("Saving…", disabled: true)
        expect(page).to have_button("Cancel", disabled: true)
      end
      within(tags_cell(sale)) { expect(page).to have_css(".sales_tag", text: "VIP", count: 1) }

      release << true

      expect(page).to have_no_css("dialog")
      within(tags_cell(sale)) { expect(page).to have_css(".sales_tag", text: "Rush") }
      expect(sale.sales_tags.pluck(:name)).to match_array(%w[Rush VIP])
    ensure
      release&.push(true)
    end

    scenario "does not open the sale from clicks or keys inside the modal" do
      visit sales_path

      open_editor(sale)
      find("dialog h2").click
      toggle("Rush")
      page.driver.browser.keyboard.type(:enter)

      expect(page).to have_current_path(sales_path)
      expect(page).to have_css("dialog")
    end

    scenario "closes the modal with Escape" do
      visit sales_path

      open_editor(sale)
      page.driver.browser.keyboard.type(:escape)

      expect(page).to have_no_css("dialog")
      expect(page).to have_current_path(sales_path)
    end

    scenario "lets support staff tag sales" do
      log_out
      sign_in create(:user, :support)
      SaleTagging.create!(sale:, sales_tag: vip)
      visit sales_path

      open_editor(sale)
      toggle("Rush")
      click_button "Save"

      within(tags_cell(sale)) { expect(page).to have_css(".sales_tag", text: "Rush") }
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
      emulate_scheme = ->(value) { page.driver.browser.page.command("Emulation.setEmulatedMedia", features: [{name: "prefers-color-scheme", value:}]) }
      emulate_scheme.call("light")
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
      expect(style_of.call(".dialog_footer button[type=button]", "borderTopWidth")).to eq("1px")
      token = page.evaluate_script("getComputedStyle(document.documentElement).getPropertyValue('--corner-shape').trim()")
      expect(style_of.call(".dialog_footer button[type=button]", "cornerShape")).to eq(token)
      expect(style_of.call(".dialog_footer button[type=submit]", "cornerShape")).to eq(token)
      expect(style_of.call(".dialog_content", "cornerShape")).to eq(token)
      radius = ->(selector) { style_of.call(selector, "borderTopLeftRadius").to_f }
      expect(radius.call(".dialog_footer button[type=button]")).to be >= 20
      expect(radius.call(".dialog_footer button[type=submit]")).to be >= 20
      expect(radius.call(".dialog_content")).to be >= 32
      expect(measure(".dialog_footer button[type=button]", "height")).to eq(measure(".dialog_footer button[type=submit]", "height"))
    ensure
      emulate_scheme&.call("")
    end

    scenario "puts Save and Cancel at the left edge of the form" do
      visit sale_path(sale)
      click_button "Add tags"

      expect(measure("dialog button[type=submit]", "left")).to eq(measure(filter_field, "left"))
      expect(page).to have_css("dialog button[type=submit] + button", text: "Cancel")
    end
  end
end
