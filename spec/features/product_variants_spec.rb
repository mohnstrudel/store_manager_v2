# frozen_string_literal: true

require "rails_helper"

# rubocop:disable RSpec/ContextWording, RSpec/MultipleExpectations
# Context wordings describe functional areas being tested, not conditions
# Multiple expectations are appropriate in feature specs testing complete user flows
RSpec.describe "Product Variants Management" do
  before do
    sign_in_as_admin
    product.colors << color
    product.versions << version
    product.build_new_variants
    product.save
  end

  let!(:product) { create(:product) }
  let!(:color) { create(:color, value: "Red") }
  let!(:version) { create(:version, value: "Deluxe") }
  let(:selected_variant) { product.variants.find { |variant| variant.version_id.present? || variant.color_id.present? || variant.size_id.present? } }

  def variant_section
    all(".variant-fields").find do |section|
      title = section.find("[data-variant-fields-target='title']").text
      title.include?(version.value) && title.include?(color.value)
    end
  end

  # === SECTION 1: Display ===
  context "Displaying variants" do
    scenario "shows existing variants section on product edit page", :rubocop_todo do
      visit edit_product_path(product)

      expect(page).to have_content("Variants")
      expect(page).to have_content("Manage variants for this product")
    end

    scenario "displays all variant attributes in form fields", :rubocop_todo do
      visit edit_product_path(product)

      section = variant_section
      within section do
        expect(page).to have_field("SKU")
        expect(page).to have_field("Weight (kg)")
        expect(page).to have_field("Purchase Cost")
        expect(page).to have_field("Selling Price")
        expect(page).to have_select("Size")
        expect(page).to have_select("Version")
        expect(page).to have_select("Color")
      end
    end

    scenario "shows variant title with size, version, and color", :rubocop_todo do
      visit edit_product_path(product)

      section = variant_section
      within section do
        title_element = find("[data-variant-fields-target='title']")
        expect(title_element).to have_content("Deluxe")
        expect(title_element).to have_content("Red")
      end
    end

    scenario "shows deactivated variants with muted styling", :rubocop_todo do
      variant = selected_variant
      variant.update!(deactivated_at: Time.current)

      visit edit_product_path(product)

      section = variant_section
      expect(section[:class]).to include("opacity-50")
      within section do
        expect(page).to have_content("(Deactivated)")
      end
    end

    scenario "displays deactivated label for deactivated variants", :js do
      variant = selected_variant
      variant.update!(deactivated_at: Time.current)

      visit edit_product_path(product)

      section = variant_section
      within section do
        expect(page).to have_content("(Deactivated)")
      end
    end
  end

  # === SECTION 2: Editing Variants ===
  context "Editing existing variants" do
    scenario "updates variant SKU", :rubocop_todo do
      variant = selected_variant

      visit edit_product_path(product)

      section = variant_section
      within section do
        fill_in "SKU", with: "NEW-SKU-123"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      variant.reload
      expect(variant.sku).to eq("NEW-SKU-123")
    end

    scenario "updates variant weight", :rubocop_todo do
      variant = selected_variant

      visit edit_product_path(product)

      section = variant_section
      within section do
        fill_in "Weight (kg)", with: "2.5"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      variant.reload
      expect(variant.weight.to_s).to eq("2.5")
    end

    scenario "updates variant purchase cost", :rubocop_todo do
      variant = selected_variant

      visit edit_product_path(product)

      section = variant_section
      within section do
        fill_in "Purchase Cost", with: "35.00"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      variant.reload
      expect(variant.purchase_cost.to_s).to eq("35.0")
    end

    scenario "updates variant selling price", :rubocop_todo do
      variant = selected_variant

      visit edit_product_path(product)

      section = variant_section
      within section do
        fill_in "Selling Price", with: "79.99"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      variant.reload
      expect(variant.selling_price.to_s).to eq("79.99")
    end

    scenario "updates all pricing fields together", :rubocop_todo do
      variant = selected_variant

      visit edit_product_path(product)

      section = variant_section
      within section do
        fill_in "Weight (kg)", with: "1.5"
        fill_in "Purchase Cost", with: "25.00"
        fill_in "Selling Price", with: "49.99"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      variant.reload
      expect(variant.weight.to_s).to eq("1.5")
      expect(variant.purchase_cost.to_s).to eq("25.0")
      expect(variant.selling_price.to_s).to eq("49.99")
    end

    scenario "shows preserved values after validation error", :rubocop_todo do
      visit edit_product_path(product)

      fill_in "product_title", with: ""

      section = variant_section
      within section do
        fill_in "SKU", with: "VARIANT-SKU-123"
        fill_in "Weight (kg)", with: "3.5"
        fill_in "Purchase Cost", with: "45.00"
        fill_in "Selling Price", with: "89.99"
      end

      click_button "Update Product"

      expect(page).to have_content("Fix errors and try again")

      section = variant_section
      within section do
        expect(page).to have_field("SKU", with: "VARIANT-SKU-123")
        expect(page).to have_field("Weight (kg)", with: "3.5")
        expect(page).to have_field("Purchase Cost", with: "45.00")
        expect(page).to have_field("Selling Price", with: "89.99")
      end
    end
  end

  # === SECTION 3: Variant Destruction ===
  context "Destroying and deactivating variants" do
    scenario "hard destroys variant without sales or purchases", :rubocop_todo do
      variant = selected_variant
      variant_count = product.variants.count

      visit edit_product_path(product)

      section = variant_section
      within section do
        expect(page).to have_content("Destroy?")
        check "Destroy?"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      expect(product.variants.count).to eq(variant_count - 1)
      expect(Variant.exists?(variant.id)).to be false
    end

    scenario "soft deletes variant with sale items", :rubocop_todo do
      variant = selected_variant
      sale = create(:sale)
      SaleItem.create!(product: product, variant: variant, sale: sale, qty: 1)

      visit edit_product_path(product)

      section = variant_section
      within section do
        expect(page).to have_content("Deactivate?")
        check "Deactivate?"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      variant.reload
      expect(variant.deactivated_at).to be_present
      expect(Variant.exists?(variant.id)).to be true
    end

    scenario "soft deletes variant with purchases", :rubocop_todo do
      variant = selected_variant
      supplier = create(:supplier)
      Purchase.create!(product: product, variant: variant, supplier: supplier, amount: 1, item_price: 10)

      visit edit_product_path(product)

      section = variant_section
      within section do
        expect(page).to have_content("Deactivate?")
        check "Deactivate?"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")

      variant.reload
      expect(variant.deactivated_at).to be_present
      expect(Variant.exists?(variant.id)).to be true
    end

    scenario "shows Deactivate checkbox for variants with sales", :rubocop_todo do
      variant = selected_variant
      sale = create(:sale)
      SaleItem.create!(product: product, variant: variant, sale: sale, qty: 1)

      visit edit_product_path(product)

      section = variant_section
      within section do
        expect(page).to have_content("Deactivate?")
        expect(page).not_to have_content("Destroy?")
      end
    end

    scenario "shows Destroy checkbox for variants without sales/purchases", :rubocop_todo do
      visit edit_product_path(product)

      section = variant_section
      within section do
        expect(page).to have_content("Destroy?")
        expect(page).not_to have_content("Deactivate?")
      end
    end

    scenario "prevents checkbox interaction for deactivated variants", :rubocop_todo do
      variant = selected_variant
      variant.update!(deactivated_at: Time.current)

      visit edit_product_path(product)

      section = variant_section
      expect(section[:class]).to include("opacity-50")
      within section do
        expect(page).to have_content("(Deactivated)")
        expect(page).not_to have_content("Destroy?")
        expect(page).not_to have_content("Deactivate?")
      end
    end
  end

  # === SECTION 4: Add/Remove Variant Forms ===
  context "Adding and removing variant forms" do
    scenario "clicking Add Variant button creates new form", :js, :rubocop_todo do
      visit edit_product_path(product)

      initial_count = all(".variant-fields").count

      click_button "Add Variant"

      expect(all(".variant-fields").count).to eq(initial_count + 1)

      new_section = all(".variant-fields").last
      within new_section do
        expect(page).to have_content("New Variant")
      end
    end

    scenario "new variant form has Remove button", :js do
      visit edit_product_path(product)

      click_button "Add Variant"

      new_section = all(".variant-fields").last
      within new_section do
        expect(page).to have_link("Remove")
      end
    end

    scenario "open variant form updates when product options change", :js do
      create(:size, value: "Large")
      create(:version, value: "Premium")
      create(:color, value: "Blue")

      visit edit_product_path(product)

      click_button "Add Variant"
      section = all(".variant-fields").last

      find("label", text: "Size", match: :first).find(:xpath, "..").find(".ss-main").click
      find(".ss-option", text: "Large").click

      find("label", text: "Version", match: :first).find(:xpath, "..").find(".ss-main").click
      find(".ss-option", text: "Premium").click

      find("label", text: "Color", match: :first).find(:xpath, "..").find(".ss-main").click
      find(".ss-option", text: "Blue").click

      within section do
        expect(page).to have_select("Size", with_options: ["", "Large"])
        expect(page).to have_select("Version", with_options: ["", "Premium"])
        expect(page).to have_select("Color", with_options: ["", "Blue"])
      end
    end

    scenario "clicking Remove button deletes the form", :js do
      visit edit_product_path(product)

      click_button "Add Variant"
      count_after_add = all(".variant-fields").count

      new_section = all(".variant-fields").last
      within new_section do
        click_link "Remove"
      end

      expect(all(".variant-fields").count).to eq(count_after_add - 1)
    end

    scenario "can add multiple variant forms", :js do
      visit edit_product_path(product)

      initial_count = all(".variant-fields").count

      click_button "Add Variant"
      click_button "Add Variant"
      click_button "Add Variant"

      expect(all(".variant-fields").count).to eq(initial_count + 3)
    end

    scenario "can remove multiple variant forms independently", :js, :rubocop_todo do
      visit edit_product_path(product)

      # Add two new variants
      click_button "Add Variant"
      click_button "Add Variant"

      count_after_add = all(".variant-fields").count
      sections = all(".variant-fields")

      # Remove the first new variant
      within all(".variant-fields").last(2).first do
        click_link "Remove"
      end

      expect(all(".variant-fields").count).to eq(count_after_add - 1)

      # Remove the second new variant
      within all(".variant-fields").last do
        click_link "Remove"
      end

      expect(all(".variant-fields").count).to eq(count_after_add - 2)
    end
  end

  # === SECTION 5: Variant Title Updates ===
  context "Variant title behavior" do
    scenario "new variant shows 'New Variant' title initially", :js do
      visit edit_product_path(product)

      click_button "Add Variant"

      new_section = all(".variant-fields").last
      within new_section do
        title_element = find("[data-variant-fields-target='title']")
        expect(title_element).to have_content("New Variant")
      end
    end

    scenario "title updates to show selected attributes", :js, :rubocop_todo do
      new_size = create(:size, value: "Large")
      new_version = create(:version, value: "Premium")
      new_color = create(:color, value: "Blue")

      product.sizes << new_size
      product.versions << new_version
      product.colors << new_color
      product.save

      visit edit_product_path(product)

      click_button "Add Variant"

      new_section = all(".variant-fields").last
      within new_section do
        select("Large", from: "Size")
        select("Premium", from: "Version")
        select("Blue", from: "Color")

        title_element = find("[data-variant-fields-target='title']")
        expect(title_element).to have_content("Large")
        expect(title_element).to have_content("Premium")
        expect(title_element).to have_content("Blue")
      end
    end

    scenario "title shows 'Base Model' when no attributes selected", :js do
      visit edit_product_path(product)

      click_button "Add Variant"

      new_section = all(".variant-fields").last
      within new_section do
        # Deselect any options by selecting blank (first option)
        find("select[name$='[size_id]']").select("", wait: 0.1)
        find("select[name$='[version_id]']").select("", wait: 0.1)
        find("select[name$='[color_id]']").select("", wait: 0.1)

        title_element = find("[data-variant-fields-target='title']")
        # Wait for the title to update via Stimulus
        expect(title_element).to have_content("Base Model", wait: 1)
      end
    end

    scenario "changing existing variant shows arrow notation", :js, :rubocop_todo do
      new_size = create(:size, value: "Large")
      product.sizes << new_size
      product.save

      visit edit_product_path(product)

      section = variant_section
      within section do
        original_title = find("[data-variant-fields-target='title']").text

        select("Large", from: "Size")

        title_element = find("[data-variant-fields-target='title']")
        expect(title_element).to have_content("→")
        expect(title_element).to have_content(original_title.split("→").first.strip)
      end
    end

    scenario "title clears arrow notation when changed back to original", :js, :rubocop_todo do
      new_size = create(:size, value: "Large")
      product.sizes << new_size
      product.save

      visit edit_product_path(product)

      section = variant_section
      within section do
        # Store the original title
        title_element = find("[data-variant-fields-target='title']")
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
      # Create another variant with a unique combination
      new_size = create(:size, value: "Large")
      new_version = create(:version, value: "Premium")
      product.sizes << new_size
      product.versions << new_version
      product.save

      # Create a second variant with specific attributes
      create(:variant, product: product, size: new_size, version: new_version, color: nil)
    end

    scenario "displays duplicate warning element on page", :js do
      visit edit_product_path(product)

      variant_section = all(".variant-fields").first
      expect(variant_section).to have_selector("[data-variant-fields-target='duplicateWarning']", visible: :all)
    end

    scenario "hides warning initially by default", :js do
      visit edit_product_path(product)

      variant_section = all(".variant-fields").first
      duplicate_warning = variant_section.find("[data-variant-fields-target='duplicateWarning']", visible: :all)
      expect(duplicate_warning).to match_css(".hidden")
    end
  end

  # === SECTION 7: Opacity Styling ===
  context "Opacity styling" do
    scenario "deactivated variants have opacity-50 class", :js do
      variant = selected_variant
      variant.update!(deactivated_at: Time.current)

      visit edit_product_path(product)

      section = variant_section
      expect(section[:class]).to include("opacity-50")
    end

    scenario "checking destroy checkbox applies opacity-50 class", :js do
      visit edit_product_path(product)

      section = variant_section
      # Style may be nil initially, which is fine
      initial_style = section[:style]
      expect(initial_style.nil? || initial_style.exclude?("opacity")).to be true

      within section do
        check "Destroy?"
      end

      expect(section[:style]).to include("opacity: 0.5")
    end

    scenario "unchecking destroy checkbox removes opacity-50 class", :js do
      visit edit_product_path(product)

      section = variant_section

      within section do
        check "Destroy?"
      end

      expect(section[:style]).to include("opacity: 0.5")

      within section do
        uncheck "Destroy?"
      end

      expect(section[:style]).to include("opacity: 1")
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

    scenario "preserves variant values on validation error" do
      visit edit_product_path(product)

      fill_in "product_title", with: ""

      section = variant_section
      within section do
        fill_in "SKU", with: "VARIANT-SKU-123"
        fill_in "Weight (kg)", with: "3.5"
        fill_in "Purchase Cost", with: "45.00"
        fill_in "Selling Price", with: "89.99"
      end

      click_button "Update Product"

      expect(page).to have_content("Fix errors and try again")

      section = variant_section
      within section do
        expect(page).to have_field("SKU", with: "VARIANT-SKU-123")
        expect(page).to have_field("Weight (kg)", with: "3.5")
        expect(page).to have_field("Purchase Cost", with: "45.00")
        expect(page).to have_field("Selling Price", with: "89.99")
      end
    end

    scenario "clears errors after successful update", :js do
      visit edit_product_path(product)

      section = variant_section
      within section do
        fill_in "SKU", with: "VALID-SKU"
      end

      click_button "Update Product"

      expect(page).to have_content("Product was successfully updated")
      expect(page).not_to have_content("Fix errors and try again")
    end
  end

  # === SECTION 9: Variant Error Handling ===
  context "Variant error handling" do
    let!(:other_product) { create(:product) }
    # rubocop:disable RSpec/LetSetup
    let!(:other_product_variant) { create(:variant, product: other_product, sku: "EXISTING-SKU-999") }
    # rubocop:enable RSpec/LetSetup

    scenario "editing existing variant with duplicate SKU shows inline error" do
      visit edit_product_path(product)

      section = variant_section
      within section do
        fill_in "SKU", with: "EXISTING-SKU-999"
      end

      click_button "Update Product"

      expect(page).to have_content("Fix errors and try again")
      expect(page).to have_css(".field_with_errors input[name*='[sku]']")
      expect(page).to have_css(".text-error", text: "has already been taken")
    end

    scenario "new variant is preserved on validation failure", :js do
      visit edit_product_path(product)

      click_button "Add Variant"

      new_section = all(".variant-fields").last
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

      # New variant should still be present with its values
      new_section = all(".variant-fields").last
      within new_section do
        expect(page).to have_content("New Variant")
        expect(page).to have_link("Remove")
        expect(page).to have_field("SKU", with: "NEW-SKU-123")
        expect(page).to have_field("Weight (kg)", with: "2.5")
        expect(page).to have_field("Purchase Cost", with: "30.00")
        expect(page).to have_field("Selling Price", with: "59.99")
      end
    end

    scenario "new variant uses the currently selected product options", :js do
      create(:size, value: "Large")
      create(:version, value: "Premium")
      create(:color, value: "Blue")

      visit edit_product_path(product)

      find("label", text: "Size", match: :first).find(:xpath, "..").find(".ss-main").click
      find(".ss-option", text: "Large").click

      find("label", text: "Version", match: :first).find(:xpath, "..").find(".ss-main").click
      find(".ss-option", text: "Premium").click

      find("label", text: "Color", match: :first).find(:xpath, "..").find(".ss-main").click
      find(".ss-option", text: "Blue").click

      click_button "Add Variant"

      new_section = all(".variant-fields").last

      size_options = new_section.all("select[name$='[size_id]'] option", visible: :all).map(&:text)
      version_options = new_section.all("select[name$='[version_id]'] option", visible: :all).map(&:text)
      color_options = new_section.all("select[name$='[color_id]'] option", visible: :all).map(&:text)

      expect(size_options).to include("Large")
      expect(version_options).to include("Premium")
      expect(color_options).to include("Blue")
    end

    scenario "duplicate combination error is displayed in error notice", :js do
      # Create another variant with a specific combination
      new_size = create(:size, value: "Large")
      product.sizes << new_size
      product.save

      # Build and create a variant with just the size (no version, no color)
      duplicate_variant = product.variants.build(size: new_size, version: nil, color: nil, sku: "large-only-duplicate")
      duplicate_variant.save!

      # Verify the duplicate variant was created correctly
      expect(product.variants.count).to be > 1
      expect(duplicate_variant.size_id).to eq(new_size.id)
      expect(duplicate_variant.version_id).to be_nil
      expect(duplicate_variant.color_id).to be_nil

      visit edit_product_path(product)

      # Try to add a new variant with the same combination
      click_button "Add Variant"

      # Find the new variant form (the last one)
      new_section = all(".variant-fields").last

      # Target the size select specifically in the new variant form
      size_select = new_section.find("select[name$='[size_id]']")
      size_select.select("Large")

      click_button "Update Product"

      expect(page).to have_content("Fix errors and try again")
      expect(page).to have_content(/Combination.*already exists/i)
    end

    scenario "successful update redirects to product show page" do
      variant = selected_variant

      visit edit_product_path(product)

      section = variant_section
      within section do
        fill_in "SKU", with: "UNIQUE-SKU-456"
      end

      click_button "Update Product"

      expect(page).to have_current_path(product_path(product))
      expect(page).to have_content("Product was successfully updated")

      variant.reload
      expect(variant.sku).to eq("UNIQUE-SKU-456")
    end
  end
end

# rubocop:enable RSpec/ContextWording, RSpec/MultipleExpectations
