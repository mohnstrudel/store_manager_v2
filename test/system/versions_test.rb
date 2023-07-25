require "application_system_test_case"

class VersionsTest < ApplicationSystemTestCase
  setup do
    @version = versions(:one)
  end

  test "visiting the index" do
    visit versions_url
    assert_selector "h1", text: "Versions"
  end

  test "should create version" do
    visit versions_url
    click_on "New version"

    click_on "Create Version"

    assert_text "Version was successfully created"
    click_on "Back"
  end

  test "should update Version" do
    visit version_url(@version)
    click_on "Edit this version", match: :first

    click_on "Update Version"

    assert_text "Version was successfully updated"
    click_on "Back"
  end

  test "should destroy Version" do
    visit version_url(@version)
    click_on "Destroy this version", match: :first

    assert_text "Version was successfully destroyed"
  end
end
