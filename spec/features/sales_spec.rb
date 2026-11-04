# frozen_string_literal: true

require "rails_helper"

describe "GET /sales" do
  before { sign_in_as_admin }
  after { log_out }

  it "renders Sales navigation before the server responds and then loads the listing", :js do
    create(:sale, shopify_name: "NAVIGATION-SALE")
    visit customers_path
    expect(page).to have_css("h1", text: "Customers")

    page.execute_script(<<~JS)
      window.heldNavigationRequests = [];
      window.originalNavigationSend = XMLHttpRequest.prototype.send;
      XMLHttpRequest.prototype.send = function (...args) {
        window.heldNavigationRequests.push(() => window.originalNavigationSend.apply(this, args));
      };
    JS

    within("nav[aria-label='Main navigation']") { click_link "Sales" }

    expect(page).to have_css("h1", text: "Sales")
    expect(page).to have_css("button[aria-pressed='true']", text: "Newest first")
    expect(page).to have_field("Hide Partial Payments", checked: false)
    expect(page).to have_field("Missing Purchases Only", checked: false)

    page.execute_script(<<~JS)
      XMLHttpRequest.prototype.send = window.originalNavigationSend;
      window.heldNavigationRequests.splice(0).forEach((send) => send());
    JS

    expect(page).to have_text("NAVIGATION-SALE")
  end

  it "shows warehouse buttons instead of sale status on the index page", :js do
    sale = create(:sale, status: Sale::ACTIVE_STATUSES.first)
    product = create(:product)
    sale_item = create(:sale_item, sale:, product:)
    warehouse = create(:warehouse, name: "Berlin Hub")
    purchase = create(:purchase, product:)
    purchase_item = create(:purchase_item, purchase:, warehouse:, sale_item:)

    visit sales_path

    expect(page).to have_css("a[href='#{purchase_item_path(purchase_item)}']", text: "Berlin Hub")
    expect(page).not_to have_text(sale.status.titleize)
  end

  describe "procurement queue", :js do
    let(:applied_query) do
      {"q" => "batch", "sort" => "oldest", "hide_partial_payments" => "1", "missing_purchases_only" => "1"}
    end

    def create_batch_sale(name, day:, linked: 0, **attributes)
      sale = create(:sale, shopify_name: name, woo_created_at: Time.utc(2024, 1, 1) + day.days, **attributes)
      sale_item = create(:sale_item, sale:, product: create(:product), qty: 1)
      create_list(:purchase_item, linked, purchase: create(:purchase, product: sale_item.product), sale_item:)
      sale
    end

    def create_follow_up_plan
      SalePaymentPlan.reconcile(
        attributes: {
          provider: "seal",
          external_id: "subscription-900",
          external_origin_order_id: "900",
          kind: "installments",
          status: "active",
          expected_parts: 2,
          synced_at: Time.current
        },
        parts: [
          {provider_part_id: "900-1", sequence: 1, external_order_id: "900"},
          {provider_part_id: "900-2", sequence: 2, external_order_id: "901"}
        ]
      )
    end

    def query_params
      Rack::Utils.parse_query(URI.parse(page.current_url).query)
    end

    def rendered_listing_query
      href = first("nav[aria-label='Pagination'] a")[:href]

      Rack::Utils.parse_query(URI.parse(href).query).except("page")
    end

    def expect_applied_query(expected)
      page.document.synchronize do
        unless query_params == expected && rendered_listing_query == expected
          raise Capybara::ExpectationNotMet, "expected #{expected}, got url #{query_params}, listing #{rendered_listing_query}"
        end
      end
    end

    def expect_controls(q:, sort:, hide:, show:)
      expect(page).to have_field("q", with: q)
      expect(page).to have_css("button[aria-pressed='true']", text: sort, exact_text: true)
      expect(page).to have_field("Hide Partial Payments", checked: hide)
      expect(page).to have_field("Missing Purchases Only", checked: show)
    end

    def pagination_link(label)
      first("nav[aria-label='Pagination']").click_link(label)
    end

    def fail_next_listing_requests
      page.execute_script(<<~JS)
        document.addEventListener("inertia:networkError", (event) => event.preventDefault());
        document.addEventListener("inertia:finish", () => { document.body.dataset.visitFinished = "1"; });
        window.restoreXhrOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function (method, _url, ...rest) {
          return window.restoreXhrOpen.call(this, method, "http://127.0.0.1:1/offline", ...rest);
        };
      JS
    end

    def restore_listing_requests
      page.execute_script("XMLHttpRequest.prototype.open = window.restoreXhrOpen; delete document.body.dataset.visitFinished;")
    end

    def hold_listing_requests
      page.execute_script(<<~JS)
        window.heldRequests = [];
        window.restoreXhrSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.send = function (...args) {
          window.heldRequests.push(() => window.restoreXhrSend.apply(this, args));
        };
      JS
    end

    def release_listing_requests
      page.execute_script(<<~JS)
        XMLHttpRequest.prototype.send = window.restoreXhrSend;
        window.heldRequests.splice(0).forEach((send) => send());
      JS
    end

    it "keeps the oldest-first queue consistent across pages, reload, history, recovery and failure" do
      create_batch_sale("BATCH-FOLLOW-UP", day: 0, shopify_store_id: "gid://shopify/Order/901")
      create_batch_sale("BATCH-COVERED", day: 0, linked: 1)
      create_batch_sale("BATCH-001", day: 1, shopify_store_id: "gid://shopify/Order/900", received_revenue: 0, outstanding_revenue: 500)
      (2..51).each { |day| create_batch_sale(format("BATCH-%03d", day), day:) }
      create_follow_up_plan

      visit sales_path
      fill_in "q", with: "batch"
      click_button "Oldest first"
      expect_applied_query("q" => "batch", "sort" => "oldest")
      check "Hide Partial Payments"
      expect_applied_query("q" => "batch", "sort" => "oldest", "hide_partial_payments" => "1")
      check "Missing Purchases Only"
      expect_applied_query(applied_query)

      expect(page).to have_css("tbody tr", count: 50)
      expect(first("tbody tr")).to have_text("BATCH-001")
      expect(page).to have_no_text("BATCH-FOLLOW-UP")
      expect(page).to have_no_text("BATCH-COVERED")
      expect(page).to have_css("nav[aria-label='Pagination']", count: 2)
      expect(query_params).to eq(applied_query)
      expect_controls(q: "batch", sort: "Oldest first", hide: true, show: true)

      pagination_link("2")

      expect(page).to have_css("tbody tr", count: 1)
      expect(first("tbody tr")).to have_text("BATCH-051")
      expect(query_params).to eq(applied_query.merge("page" => "2"))
      expect_controls(q: "batch", sort: "Oldest first", hide: true, show: true)

      page.refresh

      expect(page).to have_css("tbody tr", count: 1)
      expect(first("tbody tr")).to have_text("BATCH-051")
      expect_controls(q: "batch", sort: "Oldest first", hide: true, show: true)

      page.go_back

      expect(page).to have_css("tbody tr", count: 50)
      expect(first("tbody tr")).to have_text("BATCH-001")
      expect(query_params).to eq(applied_query)
      expect_controls(q: "batch", sort: "Oldest first", hide: true, show: true)

      fail_next_listing_requests
      fill_in "q", with: "nothing-matches"
      click_button "Search"

      expect(page).to have_css("body[data-visit-finished]")
      expect(page).to have_css("tbody tr", count: 50)
      expect(first("tbody tr")).to have_text("BATCH-001")
      expect(page).to have_field("q", with: "nothing-matches")

      restore_listing_requests
      find_field("q").send_keys(:enter)

      expect(page).to have_text("Nothing found")
      expect_controls(q: "nothing-matches", sort: "Oldest first", hide: true, show: true)

      page.driver.resize(360, 844)

      expect(page).to have_button("Search")
      expect(page).to have_button("Clear search")
      expect(page).to have_css("fieldset[aria-label='Sort sales'] button", count: 2)
      expect(page.evaluate_script("document.documentElement.scrollWidth <= window.innerWidth + 1")).to be(true)

      click_button "Clear search"

      expect(page).to have_css("tbody tr", count: 50)
      expect(first("tbody tr")).to have_text("BATCH-001")
      expect(query_params).to eq(applied_query.except("q"))
      expect_controls(q: "", sort: "Oldest first", hide: true, show: true)

      click_button "Newest first"
      expect_applied_query(applied_query.except("q", "sort"))
      uncheck "Hide Partial Payments"
      expect_applied_query("missing_purchases_only" => "1")
      uncheck "Missing Purchases Only"
      expect_applied_query({})

      expect(page).to have_css("tbody tr", count: 50)
      expect(query_params).to be_empty
      expect_controls(q: "", sort: "Newest first", hide: false, show: false)
    ensure
      page.driver.resize(1200, 768)
    end

    it "keeps text typed while a listing request is pending" do
      create_batch_sale("BATCH-001", day: 1)

      visit sales_path
      hold_listing_requests
      click_button "Oldest first"
      fill_in "q", with: "typed while pending"
      release_listing_requests

      expect(page).to have_css("th", text: "▴")
      expect(page).to have_field("q", with: "typed while pending")
      expect(page.evaluate_script("document.activeElement.name")).to eq("q")
      expect(query_params).to eq("sort" => "oldest")
    end
  end

  describe "tag filter", :js do
    let!(:vip) { create(:sales_tag, name: "VIP") }
    let!(:blue) { create(:sales_tag, name: "Blue") }
    let(:unavailable_notice) { "That tag is no longer available. Showing all tags." }

    before do
      allow(Sale).to receive(:default_per_page).and_return(2)
      create_tagged_sale("BATCH-A", day: 1, tag: vip)
      create_tagged_sale("BATCH-B", day: 2, tag: vip)
      create_tagged_sale("BATCH-C", day: 3, tag: blue)
      create_tagged_sale("BATCH-E", day: 5, tag: vip)
    end

    def create_tagged_sale(name, day:, tag:)
      create(:sale, shopify_name: name, woo_created_at: Time.utc(2024, 1, 1) + day.days, note: "batch").tap do |sale|
        SaleTagging.create!(sale:, sales_tag: tag)
      end
    end

    def query_params
      Rack::Utils.parse_query(URI.parse(page.current_url).query)
    end

    def toggle_tag(name)
      click_button "Filter by tag"
      within("dialog") do
        find("label.sales_tag_choice", text: name).click
        click_button "Apply filter"
      end
    end

    def expect_rows(*names)
      expect(page).to have_css("tbody tr", count: names.size)
      expect(page.all("tbody tr").map { |row| names.find { |name| row.has_text?(name) } }).to eq(names)
    end

    def expect_selected_tag(name)
      within("fieldset[aria-label='Tag filter']") do
        expect(page).to have_css(".sales_tag", text: name, exact_text: true)
      end
    end

    def expect_no_selected_tag
      expect(page).to have_css("fieldset[aria-label='Tag filter']")
      expect(page).to have_no_css("fieldset[aria-label='Tag filter'] .sales_tag")
    end

    def measure(selector, dimension)
      page.evaluate_script("document.querySelector(#{selector.to_json}).getBoundingClientRect().#{dimension}")
    end

    def vertical_center(selector)
      measure(selector, "top") + (measure(selector, "height") / 2)
    end

    it "keeps the tag through pages, reload, history and clearing, with the other criteria" do
      visit sales_path(q: "batch", sort: "oldest")
      expect_rows("BATCH-A", "BATCH-B")

      toggle_tag("VIP")

      expect_rows("BATCH-A", "BATCH-B")
      expect(page).to have_css("nav[aria-label='Pagination']", count: 2)
      expect(query_params).to eq("q" => "batch", "sort" => "oldest", "tag_id" => vip.id.to_s)
      expect_selected_tag("VIP")

      first("nav[aria-label='Pagination']").click_link("2")

      expect_rows("BATCH-E")
      expect(query_params).to eq("q" => "batch", "sort" => "oldest", "tag_id" => vip.id.to_s, "page" => "2")

      page.refresh

      expect_rows("BATCH-E")
      expect_selected_tag("VIP")

      page.go_back

      expect_rows("BATCH-A", "BATCH-B")
      expect(query_params).to eq("q" => "batch", "sort" => "oldest", "tag_id" => vip.id.to_s)
      expect_selected_tag("VIP")

      within("fieldset[aria-label='Tag filter']") { click_button "VIP" }

      expect_rows("BATCH-A", "BATCH-B")
      expect_no_selected_tag
      expect(query_params).to eq("q" => "batch", "sort" => "oldest")
      expect(page).to have_css("nav[aria-label='Pagination'] a", text: "2", minimum: 1)
    end

    it "lays the sort tabs, filters and Filter by tag button on one row, aligned with the search field" do
      page.driver.resize(1400, 800)
      visit sales_path
      expect(page).to have_css("fieldset[aria-label='Tag filter'] button", text: "Filter by tag")

      expect(measure("fieldset[aria-label='Sort sales']", "left")).to eq(measure("input[name='q']", "left"))
      row_center = vertical_center("fieldset[aria-label='Sort sales']")
      ["input[name='hide_partial_payments']", "input[name='missing_purchases_only']", "fieldset[aria-label='Tag filter'] button"].each do |selector|
        expect(vertical_center(selector)).to be_within(2).of(row_center)
      end
      expect(measure("fieldset[aria-label='Tag filter'] button", "left")).to be > measure("input[name='missing_purchases_only']", "right")
    ensure
      page.driver.resize(1200, 768)
    end

    it "leaves a visible sale's row and the totals when its active tag is removed" do
      visit sales_path(q: "batch", sort: "oldest", tag_id: vip.id)
      expect_rows("BATCH-A", "BATCH-B")

      within("tbody tr", text: "BATCH-A") { click_button "Edit" }
      find("dialog label.sales_tag_choice", text: "VIP").click
      click_button "Save"

      expect(page).to have_no_css("dialog")
      expect_rows("BATCH-B", "BATCH-E")
      expect(query_params).to eq("q" => "batch", "sort" => "oldest", "tag_id" => vip.id.to_s)
    end

    it "clears a deleted active tag with the explanation and a canonical URL on the next listing change" do
      visit sales_path(q: "batch", sort: "oldest", tag_id: vip.id)
      expect_selected_tag("VIP")

      vip.destroy!
      click_button "Newest first"

      expect(page).to have_content(unavailable_notice)
      expect_no_selected_tag
      expect(query_params).to eq("q" => "batch")
      expect_rows("BATCH-E", "BATCH-C")
    end

    it "drops a deleted active tag from the controls when the tags are reloaded" do
      visit sales_path(q: "batch", sort: "oldest", tag_id: vip.id)
      within("tbody tr", text: "BATCH-A") { click_button "Edit" }
      find("dialog label.sales_tag_choice", text: "Blue").click

      vip.destroy!
      click_button "Save"
      expect(page).to have_content("Tags changed since you opened this editor")
      click_button "Reload tags (discards your changes)"

      expect(page).to have_no_css("dialog")
      expect_no_selected_tag
      expect(query_params).to eq("q" => "batch", "sort" => "oldest")
      expect_rows("BATCH-A", "BATCH-B")
    end
  end

  describe "button shape", :js do
    it "gives every regular header button the same very squircle shape" do
      visit sales_path
      expect(page).to have_css("header menu button", text: "Store Sync")

      shapes = page.evaluate_script(<<~JS)
        [...document.querySelectorAll("header menu a, header menu button")].map((element) => {
          const style = getComputedStyle(element);
          return [element.textContent.trim(), style.cornerShape, parseFloat(style.borderTopLeftRadius)];
        })
      JS

      token = page.evaluate_script("getComputedStyle(document.documentElement).getPropertyValue('--corner-shape').trim()")
      expect(shapes.size).to be >= 2
      expect(shapes.map { |_, corner_shape, _| corner_shape }.uniq).to eq([token])
      expect(shapes.map { |_, _, radius| radius }).to all(be >= 20)
    end
  end

  describe "store sync dialog" do
    it "centers the close button on the title, not on the title with its subtitle", :js do
      allow(Config).to receive(:shopify_sales_sync_time).and_return("20.05 at 10:00")
      visit sales_path

      click_button "Store Sync"

      expect(page).to have_css("dialog p", text: "Last sync: 20.05 at 10:00")
      center = ->(selector) { page.evaluate_script("(() => { const box = document.querySelector(#{selector.to_json}).getBoundingClientRect(); return box.top + box.height / 2; })()") }
      expect(center.call("dialog h2")).to be_within(1).of(center.call("dialog [aria-label='Close']"))
    end
  end
end
