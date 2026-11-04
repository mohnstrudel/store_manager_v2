# frozen_string_literal: true

require "rails_helper"
require "base64"

RSpec.describe "Product index thumbnails", :js do
  before { sign_in_as_admin }

  after do
    cleanup_file("product-index-visible.png")
  end

  scenario "loads the real thumbnail blob and zooms it on hover" do
    page.driver.resize(1200, 900)

    visible_product = create(:product, title: "Visible Product")
    attach_valid_image_to(visible_product, "product-index-visible.png")

    visit products_path

    visible_image = page.find("img[alt='Visible Product']")
    expect(visible_image["loading"]).to eq("lazy")
    expect(visible_image[:class]).to include("zoomable")
    expect(visible_image["src"]).to be_present
    expect(page).to have_no_css("img[alt='Visible Product'].is-loading", wait: 10)

    visible_image.hover

    visible_scale = page.evaluate_script(<<~JS)
      (() => getComputedStyle(document.querySelector("img[alt='Visible Product']")).scale)()
    JS

    expect(visible_scale).not_to eq("none")
  end

  def attach_valid_image_to(product, filename)
    create_valid_test_png(filename)
    media = create(:media, :for_product, mediaable: product)
    media.image.purge
    media.image.attach(
      io: Rails.root.join("tmp", filename).open("rb"),
      filename:,
      content_type: "image/png"
    )
  end

  def create_valid_test_png(filename)
    Rails.root.join("tmp", filename).binwrite(Base64.decode64(valid_test_png_base64))
  end

  def valid_test_png_base64
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aW1cAAAAASUVORK5CYII="
  end

  def cleanup_file(filename)
    path = Rails.root.join("tmp", filename)
    File.delete(path) if File.exist?(path)
  end
end
