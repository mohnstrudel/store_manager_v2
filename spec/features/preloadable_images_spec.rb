# frozen_string_literal: true

require "rails_helper"
require "base64"

RSpec.describe "Preloadable images", :js do
  before { sign_in_as_admin }

  after do
    cleanup_file("preloadable-thumb.png")
  end

  # rubocop:todo RSpec/MultipleExpectations
  scenario "loads a visible product thumbnail on the products index" do
    product = create(:product)
    attach_valid_image_to(product, "preloadable-thumb.png")

    visit products_path

    expect(page).to have_css("[data-controller='preloadable-img']")
    expect(page).to have_no_css(".preloadable-img__img.loading", wait: 10)

    image_state = page.evaluate_script(<<~JS)
      (() => {
        const image = document.querySelector(".preloadable-img__img")

        return {
          hidden: image.classList.contains("hidden"),
          loading: image.classList.contains("loading"),
          src: image.getAttribute("src")
        }
      })()
    JS

    aggregate_failures do
      expect(image_state["hidden"]).to be(false)
      expect(image_state["loading"]).to be(false)
      expect(image_state["src"]).to be_present
    end
  end
  # rubocop:enable RSpec/MultipleExpectations

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
