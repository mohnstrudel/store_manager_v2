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
    sale = create(:sale, status: Sale.active_status_names.first)
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
      SalePaymentPlan.reconcile!(
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
end
