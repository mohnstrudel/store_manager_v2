# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Mobile support", :js do
  before do
    sign_in_as_admin
    page.driver.resize(360, 844)
  end

  after do
    log_out
  end

  let!(:warehouse) { create(:warehouse, is_default: true) }
  let!(:franchise) { create(:franchise) }
  let!(:customer) { create(:customer, email: "mobile@example.com") }
  let!(:product) { create(:product, franchise:) }
  let!(:sale) { create(:sale, customer:) }
  let!(:purchase) { create(:purchase, product:) }

  def expect_mobile_page(label, allow_table_scroll: false)
    expect(page).to have_css("body")

    overflow_free = page.evaluate_script(
      "Math.max(document.body.scrollWidth, document.documentElement.scrollWidth) <= window.innerWidth + 1"
    )

    if allow_table_scroll
      expect(page).to have_css("table")
    else
      expect(overflow_free).to eq(true), "#{label} still overflows horizontally"
    end
  end

  def expect_no_mobile_overflow(label)
    offenders = page.evaluate_script(<<~JS)
      (() => {
        const viewportWidth = window.innerWidth;
        const allowedOverflowSelector = [
          "table",
          ".table-card",
          ".section-border-base",
          "trix-toolbar .trix-button-row"
        ].join(", ");

        return Array.from(document.querySelectorAll("body *")).filter((element) => {
          if (element.closest(allowedOverflowSelector)) return false;

          const rect = element.getBoundingClientRect();
          const overflowsViewport = rect.left < -1 || rect.right > viewportWidth + 1;
          const scrollsHorizontally = element.scrollWidth > element.clientWidth + 1;

          return overflowsViewport || scrollsHorizontally;
        }).slice(0, 8).map((element) => ({
          tag: element.tagName.toLowerCase(),
          className: element.className.toString(),
          text: element.textContent.trim().slice(0, 80),
          clientWidth: element.clientWidth,
          scrollWidth: element.scrollWidth,
          left: Math.round(element.getBoundingClientRect().left),
          right: Math.round(element.getBoundingClientRect().right)
        }));
      })()
    JS

    expect(offenders).to eq([]), "#{label} has horizontal overflow: #{offenders.inspect}"
  end

  it "keeps the main index pages within the viewport" do
    visit root_path
    expect_mobile_page("dashboard")
    expect(page).to have_no_css("nav[aria-label='Breadcrumb']")
    expect(page).to have_css("h1", text: "Dashboard")

    visit products_path
    expect_mobile_page("products index")
    expect(page).to have_css("form")

    visit sales_path
    expect_mobile_page("sales index")
    expect(page).to have_css("form")

    visit purchases_path
    expect_mobile_page("purchases index", allow_table_scroll: true)

    visit warehouses_path
    expect_mobile_page("warehouses index")
    expect(page).to have_css("h1", text: "Warehouses")
  end

  it "keeps navigation usable on mobile" do
    visit root_path

    expect(page).to have_link("Dashboard")
    expect(page).to have_link("Sales")
    expect(page).to have_css("nav[role='navigation-dropdown'] > button")

    mobile_nav_layout = page.evaluate_script(<<~JS)
      (() => {
        const logoRow = document.querySelector('[role="navigation-logo"]').getBoundingClientRect();
        const dropdown = document.querySelector('nav[role="navigation-dropdown"]');
        const dropdownRow = dropdown.getBoundingClientRect();
        const button = dropdown.querySelector('button');
        const buttonStyles = getComputedStyle(button);

        return {
          dropdownOnSameRow: Math.abs(dropdownRow.top - logoRow.top) <= 2,
          burgerButtonVisible: buttonStyles.display !== 'none',
          burgerButtonRadius: buttonStyles.borderRadius
        };
      })()
    JS

    expect(mobile_nav_layout["dropdownOnSameRow"]).to eq(true)
    expect(mobile_nav_layout["burgerButtonVisible"]).to eq(true)
    expect(mobile_nav_layout["burgerButtonRadius"]).to eq("4px")
    expect(page).to have_css("nav[role='navigation-dropdown']")
    expect(page).to have_link("Suppliers", visible: :all)
    expect_no_mobile_overflow("mobile navigation")
  end

  it "keeps the detail pages within the viewport" do
    visit product_path(product)
    expect_mobile_page("product show")
    expect(page).to have_css("h1", text: product.title)

    visit sale_path(sale)
    expect_mobile_page("sale show")
    expect(page).to have_css("h1", text: /Sale/)

    visit purchase_path(purchase)
    expect_mobile_page("purchase show")
    expect(page).to have_css("h1", text: "Purchase #{purchase.id}")

    visit warehouse_path(warehouse)
    expect_mobile_page("warehouse show")
    expect(page).to have_css("h1", text: warehouse.name)
  end

  it "keeps the main forms readable on mobile" do
    visit new_product_path
    expect_mobile_page("new product")
    expect(page).to have_css("form")

    visit edit_product_path(product)
    expect_mobile_page("edit product")
    expect_no_mobile_overflow("edit product")
    expect(page).to have_css("form")

    visit new_sale_path
    expect_mobile_page("new sale")
    expect(page).to have_css("form")

    visit edit_warehouse_path(warehouse)
    expect_mobile_page("edit warehouse")
    expect(page).to have_css("form")
  end
end
