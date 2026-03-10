# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/ContextWording, RSpec/MultipleExpectations
# Context wordings describe functional areas being tested, not conditions
# Multiple expectations are appropriate in feature specs testing complete user flows
RSpec.describe "Product Editions Management" do
  before do
    sign_in_as_admin
    product.colors << color
    product.versions << version
    product.build_new_editions
    product.save
  end

  let!(:product) { create(:product) }
  let!(:color) { create(:color, value: "Red") }
  let!(:version) { create(:version, value: "Deluxe") }

  # === SECTION 1: Display ===
  context "Displaying editions" do
    scenario "shows existing editions section on product edit page", :rubocop_todo do
      visit edit_product_path(product)

      expect(page).to have_content("Editions")
      expect(page).to have_content("Manage editions for this product")
    end

    scenario "displays all edition attributes in form fields", :rubocop_todo do
      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        expect(page).to have_field("SKU")
        expect(page).to have_field("Weight (kg)")
        expect(page).to have_field("Purchase Cost")
        expect(page).to have_field("Selling Price")
        expect(page).to have_select("Size")
        expect(page).to have_select("Version")
        expect(page).to have_select("Color")
      end
    end

    scenario "shows edition title with size, version, and color", :rubocop_todo do
      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        title_element = find("[data-edition-fields-target='title']")
        expect(title_element).to have_content("Deluxe")
        expect(title_element).to have_content("Red")
      end
    end

    scenario "shows deactivated editions with muted styling", :rubocop_todo do
      edition = product.editions.first
      edition.update!(deactivated_at: Time.current)

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      expect(edition_section[:class]).to include("opacity-50")
      within edition_section do
        expect(page).to have_content("(Deactivated)")
      end
    end

    scenario "displays deactivated label for deactivated editions", :js do
      edition = product.editions.first
      edition.update!(deactivated_at: Time.current)

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        expect(page).to have_content("(Deactivated)")
      end
    end
  end

  # === SECTION 2: Editing Editions ===
  context "Editing existing editions" do
    scenario "updates edition SKU", :rubocop_todo do
      edition = product.editions.first

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        fill_in "SKU", with: "NEW-SKU-123"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      edition.reload
      expect(edition.sku).to eq("NEW-SKU-123")
    end

    scenario "updates edition weight", :rubocop_todo do
      edition = product.editions.first

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        fill_in "Weight (kg)", with: "2.5"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      edition.reload
      expect(edition.weight.to_s).to eq("2.5")
    end

    scenario "updates edition purchase cost", :rubocop_todo do
      edition = product.editions.first

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        fill_in "Purchase Cost", with: "35.00"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      edition.reload
      expect(edition.purchase_cost.to_s).to eq("35.0")
    end

    scenario "updates edition selling price", :rubocop_todo do
      edition = product.editions.first

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        fill_in "Selling Price", with: "79.99"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      edition.reload
      expect(edition.selling_price.to_s).to eq("79.99")
    end

    scenario "updates all pricing fields together", :rubocop_todo do
      edition = product.editions.first

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        fill_in "Weight (kg)", with: "1.5"
        fill_in "Purchase Cost", with: "25.00"
        fill_in "Selling Price", with: "49.99"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      edition.reload
      expect(edition.weight.to_s).to eq("1.5")
      expect(edition.purchase_cost.to_s).to eq("25.0")
      expect(edition.selling_price.to_s).to eq("49.99")
    end

    scenario "shows preserved values after validation error", :rubocop_todo do
      visit edit_product_path(product)

      fill_in "product_title", with: ""

      edition_section = find(".edition-fields")
      within edition_section do
        fill_in "SKU", with: "EDITION-SKU-123"
        fill_in "Weight (kg)", with: "3.5"
        fill_in "Purchase Cost", with: "45.00"
        fill_in "Selling Price", with: "89.99"
      end

      click_button "Update Product"

      expect(page).to have_content("Fix errors and try again")

      edition_section = find(".edition-fields")
      within edition_section do
        expect(page).to have_field("SKU", with: "EDITION-SKU-123")
        expect(page).to have_field("Weight (kg)", with: "3.5")
        expect(page).to have_field("Purchase Cost", with: "45.00")
        expect(page).to have_field("Selling Price", with: "89.99")
      end
    end
  end

  # === SECTION 3: Edition Destruction ===
  context "Destroying and deactivating editions" do
    scenario "hard destroys edition without sales or purchases", :rubocop_todo do
      edition = product.editions.first
      edition_count = product.editions.count

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        expect(page).to have_content("Destroy?")
        check "Destroy?"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      expect(product.editions.count).to eq(edition_count - 1)
      expect(Edition.exists?(edition.id)).to be false
    end

    scenario "soft deletes edition with sale items", :rubocop_todo do
      edition = product.editions.first
      sale = create(:sale)
      SaleItem.create!(product: product, edition: edition, sale: sale, qty: 1)

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        expect(page).to have_content("Deactivate?")
        check "Deactivate?"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      edition.reload
      expect(edition.deactivated_at).to be_present
      expect(Edition.exists?(edition.id)).to be true
    end

    scenario "soft deletes edition with purchases", :rubocop_todo do
      edition = product.editions.first
      supplier = create(:supplier)
      Purchase.create!(product: product, edition: edition, supplier: supplier, amount: 1, item_price: 10)

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        expect(page).to have_content("Deactivate?")
        check "Deactivate?"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      edition.reload
      expect(edition.deactivated_at).to be_present
      expect(Edition.exists?(edition.id)).to be true
    end

    scenario "shows Deactivate checkbox for editions with sales", :rubocop_todo do
      edition = product.editions.first
      sale = create(:sale)
      SaleItem.create!(product: product, edition: edition, sale: sale, qty: 1)

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        expect(page).to have_content("Deactivate?")
        expect(page).not_to have_content("Destroy?")
      end
    end

    scenario "shows Destroy checkbox for editions without sales/purchases", :rubocop_todo do
      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        expect(page).to have_content("Destroy?")
        expect(page).not_to have_content("Deactivate?")
      end
    end

    scenario "prevents checkbox interaction for deactivated editions", :rubocop_todo do
      edition = product.editions.first
      edition.update!(deactivated_at: Time.current)

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      expect(edition_section[:class]).to include("opacity-50")
      within edition_section do
        expect(page).to have_content("(Deactivated)")
        expect(page).not_to have_content("Destroy?")
        expect(page).not_to have_content("Deactivate?")
      end
    end
  end

  # === SECTION 4: Add/Remove Edition Forms ===
  context "Adding and removing edition forms" do
    scenario "clicking Add Edition button creates new form", :rubocop_todo do
      visit edit_product_path(product)

      initial_count = all(".edition-fields").count

      click_button "Add Edition"

      expect(all(".edition-fields").count).to eq(initial_count + 1)

      new_section = all(".edition-fields").last
      within new_section do
        expect(page).to have_content("New Edition")
      end
    end

    scenario "new edition form has Remove button", :js do
      visit edit_product_path(product)

      click_button "Add Edition"

      new_section = all(".edition-fields").last
      within new_section do
        expect(page).to have_link("Remove")
      end
    end

    scenario "clicking Remove button deletes the form", :js do
      visit edit_product_path(product)

      click_button "Add Edition"
      count_after_add = all(".edition-fields").count

      new_section = all(".edition-fields").last
      within new_section do
        click_link "Remove"
      end

      expect(all(".edition-fields").count).to eq(count_after_add - 1)
    end

    scenario "can add multiple edition forms", :js do
      visit edit_product_path(product)

      initial_count = all(".edition-fields").count

      click_button "Add Edition"
      click_button "Add Edition"
      click_button "Add Edition"

      expect(all(".edition-fields").count).to eq(initial_count + 3)
    end

    scenario "can remove multiple edition forms independently", :rubocop_todo do
      visit edit_product_path(product)

      # Add two new editions
      click_button "Add Edition"
      click_button "Add Edition"

      count_after_add = all(".edition-fields").count
      sections = all(".edition-fields")

      # Remove the first new edition
      within sections[1] do
        click_link "Remove"
      end

      expect(all(".edition-fields").count).to eq(count_after_add - 1)

      # Remove the second new edition
      sections = all(".edition-fields")
      within sections[1] do
        click_link "Remove"
      end

      expect(all(".edition-fields").count).to eq(count_after_add - 2)
    end
  end

  # === SECTION 5: Edition Title Updates ===
  context "Edition title behavior" do
    scenario "new edition shows 'New Edition' title initially", :js do
      visit edit_product_path(product)

      click_button "Add Edition"

      new_section = all(".edition-fields").last
      within new_section do
        title_element = find("[data-edition-fields-target='title']")
        expect(title_element).to have_content("New Edition")
      end
    end

    scenario "title updates to show selected attributes", :rubocop_todo do
      new_size = create(:size, value: "Large")
      new_version = create(:version, value: "Premium")
      new_color = create(:color, value: "Blue")

      product.sizes << new_size
      product.versions << new_version
      product.colors << new_color
      product.save

      visit edit_product_path(product)

      click_button "Add Edition"

      new_section = all(".edition-fields").last
      within new_section do
        select("Large", from: "Size")
        select("Premium", from: "Version")
        select("Blue", from: "Color")

        title_element = find("[data-edition-fields-target='title']")
        expect(title_element).to have_content("Large")
        expect(title_element).to have_content("Premium")
        expect(title_element).to have_content("Blue")
      end
    end

    scenario "title shows 'Base Model' when no attributes selected", :js do
      visit edit_product_path(product)

      click_button "Add Edition"

      new_section = all(".edition-fields").last
      within new_section do
        # Deselect any options by selecting blank (first option)
        find("select[name$='[size_id]']").select("", wait: 0.1)
        find("select[name$='[version_id]']").select("", wait: 0.1)
        find("select[name$='[color_id]']").select("", wait: 0.1)

        title_element = find("[data-edition-fields-target='title']")
        # Wait for the title to update via Stimulus
        expect(title_element).to have_content("Base Model", wait: 1)
      end
    end

    scenario "changing existing edition shows arrow notation", :rubocop_todo do
      new_size = create(:size, value: "Large")
      product.sizes << new_size
      product.save

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        original_title = find("[data-edition-fields-target='title']").text

        select("Large", from: "Size")

        title_element = find("[data-edition-fields-target='title']")
        expect(title_element).to have_content("→")
        expect(title_element).to have_content(original_title.split("→").first.strip)
      end
    end

    scenario "title clears arrow notation when changed back to original", :rubocop_todo do
      new_size = create(:size, value: "Large")
      product.sizes << new_size
      product.save

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        # Store the original title
        title_element = find("[data-edition-fields-target='title']")
        original_text = title_element.text

        # Select new size
        select("Large", from: "Size")

        # Verify arrow notation appears
        expect(title_element).to have_content("→")

        # Change back to original (blank or original selection)
        select("", from: "Size")

        # Arrow notation should be gone, back to original title
        expect(title_element.text).to eq(original_text)
      end
    end
  end

  # === SECTION 6: Duplicate Detection ===
  context "Duplicate combination warnings" do
    before do
      # Create another edition with a unique combination
      new_size = create(:size, value: "Large")
      new_version = create(:version, value: "Premium")
      product.sizes << new_size
      product.versions << new_version
      product.save

      # Create a second edition with specific attributes
      create(:edition, product: product, size: new_size, version: new_version, color: nil)
    end

    scenario "displays duplicate warning element on page", :js do
      visit edit_product_path(product)

      edition_section = all(".edition-fields").first
      expect(edition_section).to have_selector("[data-edition-fields-target='duplicateWarning']", visible: :all)
    end

    scenario "hides warning initially by default", :js do
      visit edit_product_path(product)

      edition_section = all(".edition-fields").first
      duplicate_warning = edition_section.find("[data-edition-fields-target='duplicateWarning']", visible: :all)
      expect(duplicate_warning).to match_css(".hidden")
    end
  end

  # === SECTION 7: Opacity Styling ===
  context "Opacity styling" do
    scenario "deactivated editions have opacity-50 class", :js do
      edition = product.editions.first
      edition.update!(deactivated_at: Time.current)

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      expect(edition_section[:class]).to include("opacity-50")
    end

    scenario "checking destroy checkbox applies opacity-50 class", :js do
      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      # Style may be nil initially, which is fine
      initial_style = edition_section[:style]
      expect(initial_style.nil? || initial_style.exclude?("opacity")).to be true

      within edition_section do
        check "Destroy?"
      end

      expect(edition_section[:style]).to include("opacity: 0.5")
    end

    scenario "unchecking destroy checkbox removes opacity-50 class", :js do
      visit edit_product_path(product)

      edition_section = find(".edition-fields")

      within edition_section do
        check "Destroy?"
      end

      expect(edition_section[:style]).to include("opacity: 0.5")

      within edition_section do
        uncheck "Destroy?"
      end

      expect(edition_section[:style]).to include("opacity: 1")
    end
  end

  # === SECTION 8: Validation Errors ===
  context "Validation errors" do
    scenario "shows product error when title is blank" do
      visit edit_product_path(product)

      fill_in "product_title", with: ""

      click_button "Update Product"

      expect(page).to have_content("Fix errors and try again")
      expect(page).to have_content("Title")
    end

    scenario "preserves edition values on validation error" do
      visit edit_product_path(product)

      fill_in "product_title", with: ""

      edition_section = find(".edition-fields")
      within edition_section do
        fill_in "SKU", with: "EDITION-SKU-123"
        fill_in "Weight (kg)", with: "3.5"
        fill_in "Purchase Cost", with: "45.00"
        fill_in "Selling Price", with: "89.99"
      end

      click_button "Update Product"

      expect(page).to have_content("Fix errors and try again")

      edition_section = find(".edition-fields")
      within edition_section do
        expect(page).to have_field("SKU", with: "EDITION-SKU-123")
        expect(page).to have_field("Weight (kg)", with: "3.5")
        expect(page).to have_field("Purchase Cost", with: "45.00")
        expect(page).to have_field("Selling Price", with: "89.99")
      end
    end

    scenario "clears errors after successful update", :js do
      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        fill_in "SKU", with: "VALID-SKU"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")
      expect(page).not_to have_content("Fix errors and try again")
    end
  end

  # === SECTION 9: Edition Error Handling ===
  context "Edition error handling" do
    let!(:other_product) { create(:product) }
    # rubocop:disable RSpec/LetSetup
    let!(:other_product_edition) { create(:edition, product: other_product, sku: "EXISTING-SKU-999") }
    # rubocop:enable RSpec/LetSetup

    scenario "editing existing edition with duplicate SKU shows inline error" do
      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        fill_in "SKU", with: "EXISTING-SKU-999"
      end

      click_button "Update Product"

      expect(page).to have_content("Fix errors and try again")
      expect(page).to have_css(".field_with_errors input[name*='[sku]']")
      expect(page).to have_css(".text-error", text: "has already been taken")
    end

    scenario "new edition is preserved on validation failure", :js do
      visit edit_product_path(product)

      click_button "Add Edition"

      new_section = all(".edition-fields").last
      within new_section do
        fill_in "SKU", with: "NEW-SKU-123"
        fill_in "Weight (kg)", with: "2.5"
        fill_in "Purchase Cost", with: "30.00"
        fill_in "Selling Price", with: "59.99"
      end

      # Trigger a validation error on the product
      fill_in "product_title", with: ""

      click_button "Update Product"

      expect(page).to have_content("Fix errors and try again")

      # New edition should still be present with its values
      new_section = all(".edition-fields").last
      within new_section do
        expect(page).to have_field("SKU", with: "NEW-SKU-123")
        expect(page).to have_field("Weight (kg)", with: "2.5")
        expect(page).to have_field("Purchase Cost", with: "30.00")
        expect(page).to have_field("Selling Price", with: "59.99")
      end
    end

    scenario "duplicate combination error is displayed in error notice", :js do
      # Create another edition with a specific combination
      new_size = create(:size, value: "Large")
      product.sizes << new_size
      product.save

      # Build and create an edition with just the size (no version, no color)
      duplicate_edition = product.editions.build(size: new_size, version: nil, color: nil)
      duplicate_edition.save!

      # Verify the duplicate edition was created correctly
      expect(product.editions.count).to be > 1
      expect(duplicate_edition.size_id).to eq(new_size.id)
      expect(duplicate_edition.version_id).to be_nil
      expect(duplicate_edition.color_id).to be_nil

      visit edit_product_path(product)

      # Try to add a new edition with the same combination
      click_button "Add Edition"

      # Find the new edition form (the last one)
      new_section = all(".edition-fields").last

      # Target the size select specifically in the new edition form
      size_select = new_section.find("select[name$='[size_id]']")
      size_select.select("Large")

      click_button "Update Product"

      expect(page).to have_content("Fix errors and try again")
      expect(page).to have_content(/Combination.*already exists/i)
    end

    scenario "successful update redirects to product show page" do
      edition = product.editions.first

      visit edit_product_path(product)

      edition_section = find(".edition-fields")
      within edition_section do
        fill_in "SKU", with: "UNIQUE-SKU-456"
      end

      click_button "Update Product"

      expect(page).to have_current_path(product_path(product))
      expect(page).to have_content("Product was successfully updated")

      edition.reload
      expect(edition.sku).to eq("UNIQUE-SKU-456")
    end
  end
end

# rubocop:enable RSpec/ContextWording, RSpec/MultipleExpectations
