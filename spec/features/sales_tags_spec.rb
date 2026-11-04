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

    scenario "offers the colors as large chips like the tag dialog, spaced below their legend like the name input, checkmarking the selected one" do
      visit new_sales_tag_path
      expect(page).to have_css("dialog h2", text: "New tag")
      gap = lambda do |above, below|
        page.evaluate_script("document.querySelector(#{below.to_json}).getBoundingClientRect().top - document.querySelector(#{above.to_json}).getBoundingClientRect().bottom")
      end
      name_gap = gap.call("dialog label[for]", "dialog input:not([type=radio])")

      expect(name_gap).to be > 0
      expect(gap.call("dialog legend", "dialog .sales_tag_choices")).to eq(name_gap)

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
  end

  describe "editing" do
    let!(:sale) { create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 2)) }
    let!(:other_sale) { create(:sale, shopify_name: "HSCM#1002", woo_created_at: Time.utc(2024, 1, 1)) }
    let!(:vip) { create(:sales_tag, name: "VIP Order", color: "sky") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }

    before { [sale, other_sale].each { |target| SaleTagging.create!(sale: target, sales_tag: vip) } }

    scenario "updates a tag used by two sales from its edit dialog" do
      visit sales_tags_path

      within("tbody tr", text: "VIP Order") { click_link "Edit" }
      save_in_dialog(name: "  VIP   Client ", color: "olive", submit: "Update")

      expect(page).to have_no_css("dialog")
      expect(page).to have_current_path(sales_tags_path)
      expect(page).to have_css("tbody tr", text: "VIP Client")
      expect(vip.reload).to have_attributes(name: "VIP Client", color: "olive")
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

  describe "deleting" do
    let!(:sale) { create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 2), status: "processing") }
    let!(:completed_sale) { create(:sale, shopify_name: "HSCM#1002", woo_created_at: Time.utc(2024, 1, 1), status: "completed") }
    let!(:vip) { create(:sales_tag, name: "VIP Order", color: "sky") }
    let!(:rush) { create(:sales_tag, name: "Rush", color: "pink") }
    let(:question) { 'Delete "VIP Order" from 2 sales? Sales will be kept.' }

    before do
      [sale, completed_sale].each { |target| SaleTagging.create!(sale: target, sales_tag: vip) }
      SaleTagging.create!(sale:, sales_tag: rush)
    end

    scenario "removes the tag from every sale after confirmation and keeps the sales and their other tags" do
      visit sales_tags_path

      accept_confirm(question) { within("tbody tr", text: "VIP Order") { click_button "Delete" } }

      expect(page).to have_content("Sales tag deleted")
      expect(page).to have_no_css("tbody tr", text: "VIP Order")
      expect(page).to have_css("tbody tr", text: "Rush")
      expect(Sale.where(id: [sale, completed_sale]).count).to eq(2)
      expect(SaleTagging.pluck(:sale_id, :sales_tag_id)).to eq([[sale.id, rush.id]])
    end
  end

  describe "details" do
    let!(:vip) { create(:sales_tag, name: "VIP Order", color: "sky") }
    let!(:sale) { create(:sale, shopify_name: "HSCM#1001", woo_created_at: Time.utc(2024, 1, 2)) }
    let!(:older_sale) { create(:sale, shopify_name: "HSCM#1002", woo_created_at: Time.utc(2024, 1, 1)) }
    let!(:product) { create(:product).tap { |record| create(:media, :for_product, mediaable: record) } }
    let!(:item) { create(:sale_item, sale:, product:, variant: nil) }

    before { [sale, older_sale].each { |target| SaleTagging.create!(sale: target, sales_tag: vip) } }

    def style_of(selector, property)
      page.evaluate_script("getComputedStyle(document.querySelector(#{selector.to_json})).#{property}")
    end

    scenario "opens from a row click at its own URL, closes with Escape onto the list, and Back never reopens it" do
      visit sales_tags_path

      find("tbody tr", text: "VIP Order").click

      expect(page).to have_css("dialog h2 .sales_tag_title[data-color='sky']", text: "VIP Order")
      expect(page).to have_current_path(sales_tag_path(vip))

      press(:escape)

      expect(page).to have_no_css("dialog")
      expect(page).to have_current_path(sales_tags_path)
      page.go_back
      expect(page).to have_current_path(sales_tags_path)
      expect(page).to have_no_css("dialog")
    end

    scenario "shows a 25 wide 3:4 preview slot for every sale under a heading in the tag's own background and the heading font" do
      visit sales_tag_path(vip)
      expect(page).to have_css("ol[aria-label='Sales with this tag'] > li", count: 2)
      size = lambda do |selector|
        page.evaluate_script("(() => { const r = document.querySelector(#{selector.to_json}).getBoundingClientRect(); return [Math.round(r.width), Math.round(r.height)]; })()")
      end

      expect(size.call("ol li:first-child img, ol li:first-child [role=img]")).to eq([100, 133])
      expect(size.call("ol li:last-child [role=img]")).to eq([100, 133])
      expect(style_of("dialog h2 .sales_tag_title", "backgroundColor")).not_to eq("rgba(0, 0, 0, 0)")
      expect(style_of("dialog h2 .sales_tag_title", "fontSize")).to eq(style_of("dialog h2", "fontSize"))
      expect(style_of("dialog h2 .sales_tag_title", "fontWeight")).to eq(style_of("dialog h2", "fontWeight"))
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

    scenario "keeps the saved badges and locks the modal while saving" do
      SaleTagging.create!(sale:, sales_tag: vip)
      release = Queue.new
      allow(SaleTagging).to receive(:insert_all!).and_wrap_original do |original, *args, **kwargs|
        hold_until_released(release)
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
      within(tags_cell(sale)) { expect(page).to have_css(".inline_cell_display .sales_tag", text: "VIP", count: 1) }

      release << true

      expect(page).to have_no_css("dialog")
      within(tags_cell(sale)) { expect(page).to have_css(".sales_tag", text: "Rush") }
      expect(sale.sales_tags.pluck(:name)).to match_array(%w[Rush VIP])
    ensure
      release&.push(true)
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

    def vertical_center(selector)
      measure(selector, "top") + (measure(selector, "height") / 2)
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

    scenario "saves a selection beneath the heading" do
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

    scenario "closes without saving with Escape after focus left the form and from a backdrop click" do
      visit sale_path(sale)
      click_button "Add tags"

      find("dialog h2").click
      press(:escape)

      expect(page).to have_no_css("dialog")

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

    scenario "centers the Edit tags button vertically on the row of the tags" do
      [vip, rush].each { |tag| SaleTagging.create!(sale:, sales_tag: tag) }
      visit sale_path(sale)
      expect(page).to have_button("Edit tags")

      expect(vertical_center("ul.sales_tags + button")).to be_within(0.5).of(vertical_center("ul.sales_tags .sales_tag"))
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

    scenario "centers the title on a close button without a background and puts the actions on a full-width footer at the left edge of the form" do
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
      expect(vertical_center("dialog h2")).to be_within(1).of(vertical_center("dialog [aria-label='Close']"))
      expect(measure("dialog [aria-label='Close']", "right")).to be > measure("dialog h2", "right")
      expect(measure("dialog button[type=submit]", "left")).to eq(measure(filter_field, "left"))
      expect(page).to have_css("dialog button[type=submit] + button", text: "Cancel")
    ensure
      emulate_scheme&.call("")
    end
  end
end
