require "application_system_test_case"

class FranchisesTest < ApplicationSystemTestCase
  setup do
    @franchise = franchises(:one)
  end

  test "visiting the index" do
    visit franchises_url
    assert_selector "h1", text: "Franchises"
  end

  test "should create franchise" do
    visit franchises_url
    click_on "New franchise"

    click_on "Create Franchise"

    assert_text "Franchise was successfully created"
    click_on "Back"
  end

  test "should update Franchise" do
    visit franchise_url(@franchise)
    click_on "Edit this franchise", match: :first

    click_on "Update Franchise"

    assert_text "Franchise was successfully updated"
    click_on "Back"
  end

  test "should destroy Franchise" do
    visit franchise_url(@franchise)
    click_on "Destroy this franchise", match: :first

    assert_text "Franchise was successfully destroyed"
  end
end
