# frozen_string_literal: true

require "rails_helper"

feature "Breadcrumbs navigation", :js do
  before { sign_in_as_admin }
  after { log_out }

  let!(:product) { create(:product, title: "Test Product") }
  let!(:supplier) { create(:supplier) }
  let!(:warehouse) { create(:warehouse, name: "Main Warehouse", is_default: true) }
  let!(:purchase) { create(:purchase, product:, supplier:) }
  let!(:purchase_item) { create(:purchase_item, purchase:, warehouse:) }

  scenario "displays breadcrumbs with correct trail after navigation" do
    # Start at products index
    visit products_path
    expect(page).to have_content("Products")

    # Navigate to a product by clicking on the table row
    click_product_row
    expect(page).to have_current_path(product_path(product))
    expect_breadcrumbs_to_include("Products", product.title)

    # Navigate to edit
    click_on "Edit"
    expect_breadcrumbs_to_include("Products", product.title, "Edit #{product.title}")

    # Current page should not be a link
    expect_breadcrumb_not_to_be_a_link("Edit #{product.title}")
  end

  scenario "limits breadcrumbs to last 4 pages" do
    visit products_path
    click_product_row

    visit warehouses_path
    click_warehouse_row

    visit purchases_path
    click_purchase_row

    visit purchase_item_path(purchase_item)

    # Should only show last 4 pages
    within "[data-controller='breadcrumbs']" do
      expect(page).not_to have_content("Products")
      expect(page).to have_content(warehouse.name)
      expect(page).to have_content("Purchase #{purchase.id}")
      expect(page).to have_content("Purchase Item #{purchase_item.id}")
    end
  end

  scenario "does not create duplicates on page reload" do
    visit products_path
    click_product_row

    # Reload the page
    visit current_path

    # Should not have duplicate entries
    within "[data-controller='breadcrumbs']" do
      product_breadcrumbs = page.all("li", text: product.title)
      expect(product_breadcrumbs.count).to eq(1)
    end
  end

  scenario "does not create duplicates when visiting same page multiple times" do
    visit products_path
    click_product_row

    visit products_path
    click_product_row

    # Should not have duplicate entries
    within "[data-controller='breadcrumbs']" do
      product_breadcrumbs = page.all("li", text: product.title)
      expect(product_breadcrumbs.count).to eq(1)
    end
  end

  scenario "shows opacity gradient for breadcrumbs" do
    visit products_path
    click_product_row

    visit warehouses_path
    click_warehouse_row

    visit purchases_path

    # Check that breadcrumbs have opacity styles
    within "[data-controller='breadcrumbs']" do
      breadcrumbs = page.all("li")
      expect(breadcrumbs.length).to be >= 2

      # Current page (last breadcrumb) has class breadcrumb-current without inline opacity
      last_breadcrumb = breadcrumbs.last
      expect(last_breadcrumb[:class]).to include("breadcrumb-current")

      # Previous breadcrumbs should have inline opacity styles
      if breadcrumbs.length > 1
        first_breadcrumb = breadcrumbs.first
        expect(first_breadcrumb[:style]).to include("opacity")
      end
    end
  end

  scenario "current page is not a link" do
    visit products_path
    click_product_row

    within "[data-controller='breadcrumbs']" do
      # Current page should not be wrapped in a link
      current_breadcrumb = page.all("li").last
      expect(current_breadcrumb).not_to have_selector("a")
      expect(current_breadcrumb).to have_content(product.title)
    end
  end

  scenario "previous pages are clickable links" do
    visit products_path
    click_product_row

    visit warehouses_path

    within "[data-controller='breadcrumbs']" do
      # Previous page should be a link
      expect(page).to have_link(product.title, href: product_path(product))
    end
  end

  scenario "renders breadcrumb icons with consistent spacing" do
    visit purchases_path
    click_purchase_row
    visit purchase_item_path(purchase_item)

    within "[data-controller='breadcrumbs']" do
      purchase_breadcrumb = find("li", text: "Purchase #{purchase.id}")
      purchase_item_breadcrumb = find("li", text: "Purchase Item #{purchase_item.id}")

      expect(purchase_breadcrumb).to have_css("i.icn.mr-2", text: "💰")
      expect(purchase_item_breadcrumb).to have_css("i.icn.mr-2", text: "📦")
    end
  end

  scenario "uses correct naming for different resource types" do
    # Product page
    visit product_path(product)
    within "[data-controller='breadcrumbs']" do
      expect(page).to have_content(product.title)
    end

    # Purchase page
    visit purchase_path(purchase)
    within "[data-controller='breadcrumbs']" do
      expect(page).to have_content("Purchase #{purchase.id}")
    end

    # Purchase item page
    visit purchase_item_path(purchase_item)
    within "[data-controller='breadcrumbs']" do
      expect(page).to have_content("Purchase Item #{purchase_item.id}")
    end

    # Warehouse page
    visit warehouse_path(warehouse)
    within "[data-controller='breadcrumbs']" do
      expect(page).to have_content(warehouse.name)
    end
  end

  scenario "uses correct naming for edit pages" do
    visit edit_product_path(product)

    within "[data-controller='breadcrumbs']" do
      expect(page).to have_content("Edit #{product.title}")
    end
  end

  scenario "uses correct naming for index pages" do
    visit products_path
    within "[data-controller='breadcrumbs']" do
      expect(page).to have_content("Products")
    end

    visit purchases_path
    within "[data-controller='breadcrumbs']" do
      expect(page).to have_content("Purchases")
    end

    visit warehouses_path
    within "[data-controller='breadcrumbs']" do
      expect(page).to have_content("Warehouses")
    end
  end

  private

  def expect_breadcrumbs_to_include(*names)
    within "[data-controller='breadcrumbs']" do
      names.each do |name|
        expect(page).to have_content(name)
      end
    end
  end

  def expect_breadcrumb_not_to_be_a_link(name)
    within "[data-controller='breadcrumbs']" do
      breadcrumb = find("li", text: name)
      expect(breadcrumb).not_to have_selector("a")
    end
  end

  def click_product_row
    find("tr[tabindex='0']", text: product.full_title, match: :first).click
  end

  def click_warehouse_row
    find("tr[tabindex='0']", text: warehouse.name, match: :first).click
  end

  def click_purchase_row
    find("tr[tabindex='0']", text: purchase.product_title, match: :first).click
  end
end
