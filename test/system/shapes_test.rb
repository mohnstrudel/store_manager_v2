require "application_system_test_case"

class ShapesTest < ApplicationSystemTestCase
  setup do
    @shape = shapes(:one)
  end

  test "visiting the index" do
    visit shapes_url
    assert_selector "h1", text: "Shapes"
  end

  test "should create shape" do
    visit shapes_url
    click_on "New shape"

    click_on "Create Shape"

    assert_text "Shape was successfully created"
    click_on "Back"
  end

  test "should update Shape" do
    visit shape_url(@shape)
    click_on "Edit this shape", match: :first

    click_on "Update Shape"

    assert_text "Shape was successfully updated"
    click_on "Back"
  end

  test "should destroy Shape" do
    visit shape_url(@shape)
    click_on "Destroy this shape", match: :first

    assert_text "Shape was successfully destroyed"
  end
end
