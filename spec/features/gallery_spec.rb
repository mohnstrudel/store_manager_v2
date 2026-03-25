# frozen_string_literal: true

require "rails_helper"
require "base64"

RSpec.describe "Gallery", :js do
  before { sign_in_as_admin }

  after do
    cleanup_test_image("gallery-1.png")
    cleanup_test_image("gallery-2.png")
  end

  # rubocop:todo RSpec/MultipleExpectations
  scenario "keeps gallery geometry stable after images load" do
    product = create(:product)
    attach_gallery_images_to(product)

    visit product_path(product)
    mark_gallery_images_as_loaded

    expect(page).to have_css("[data-controller='gallery']")
    expect(page).to have_no_css(".gallery-thumb__frame.loading")
    expect(page).to have_no_css(".gallery-main__frame.loading")

    geometry = page.evaluate_script(<<~JS)
      (() => {
        const thumbFrame = document.querySelector(".gallery-thumb__frame")
        const thumbImage = document.querySelector(".gallery-thumb__image")
        const mainFrame = document.querySelector(".gallery-main__frame")
        const mainImage = document.querySelector(".gallery-main__image")

        return {
          thumbFrameHeight: thumbFrame.getBoundingClientRect().height,
          thumbImageHeight: thumbImage.getBoundingClientRect().height,
          mainFrameHeight: mainFrame.getBoundingClientRect().height,
          mainImageHeight: mainImage.getBoundingClientRect().height
        }
      })()
    JS

    aggregate_failures do
      expect(geometry["thumbFrameHeight"]).to be >= 80
      expect(geometry["thumbImageHeight"]).to be_within(1.0).of(geometry["thumbFrameHeight"])
      expect(geometry["mainFrameHeight"]).to be > 0
      expect(geometry["mainImageHeight"]).to be_within(1.0).of(geometry["mainFrameHeight"])
    end
  end

  # rubocop:todo RSpec/MultipleExpectations
  scenario "shows a visible loading state while switching gallery images" do
    product = create(:product)
    attach_gallery_images_to(product)

    visit product_path(product)
    mark_gallery_images_as_loaded

    expect(page).to have_css("[data-controller='gallery']")
    expect(page).to have_no_css(".gallery-main__frame.loading")

    initial_state = page.evaluate_script(<<~JS)
      (() => {
        const mainFrame = document.querySelector(".gallery-main__frame")
        const mainImage = document.querySelector("[data-gallery-target='main']")

        return {
          height: mainFrame.getBoundingClientRect().height,
          src: mainImage.src
        }
      })()
    JS

    page.execute_script(<<~JS)
      (() => {
        const element = document.querySelector("[data-controller='gallery']")
        const controller = window.Stimulus.getControllerForElementAndIdentifier(element, "gallery")
        if (!controller) throw new Error("Gallery controller not found")

        controller.loadCurrentImage = function() {
          const selectedSlide = this.currentSlide
          if (!selectedSlide) return

          this.startMainLoading()

          setTimeout(() => {
            this.mainTarget.src = selectedSlide.dataset.preview
            this.mainTarget.alt = selectedSlide.dataset.alt || this.mainTarget.alt
            this.finishMainLoading()
          }, 300)
        }
      })()
    JS

    find(".gallery-btn.right-0").click

    expect(page).to have_css(".gallery-main__frame.loading")

    loading_height = page.evaluate_script("document.querySelector('.gallery-main__frame').getBoundingClientRect().height")
    expect(loading_height).to be_within(1.0).of(initial_state["height"])

    expect(page).to have_no_css(".gallery-main__frame.loading")

    final_src = page.evaluate_script("document.querySelector('[data-gallery-target=\"main\"]').src")
    expect(final_src).not_to eq(initial_state["src"])
  end
  # rubocop:enable RSpec/MultipleExpectations

  def attach_gallery_images_to(product)
    create_valid_test_png("gallery-1.png")
    create_valid_test_png("gallery-2.png")

    [
      attach_image_to(create(:media, :for_product, mediaable: product), "gallery-1.png"),
      attach_image_to(create(:media, :for_product, mediaable: product), "gallery-2.png")
    ]
  end

  def attach_image_to(media, filename)
    media.image.purge
    media.image.attach(
      io: Rails.root.join("tmp", filename).open("rb"),
      filename:,
      content_type: "image/png"
    )
    media
  end

  def create_valid_test_png(filename)
    Rails.root.join("tmp", filename).binwrite(Base64.decode64(valid_test_png_base64))
  end

  def valid_test_png_base64
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aW1cAAAAASUVORK5CYII="
  end

  def mark_gallery_images_as_loaded
    page.execute_script(<<~JS)
      (() => {
        document.querySelectorAll(".gallery-thumb__image").forEach((image) => {
          image.classList.remove("hidden")
          image.closest(".gallery-thumb__frame")?.classList.remove("loading")
          image.dispatchEvent(new Event("load"))
        })

        const mainImage = document.querySelector(".gallery-main__image")
        const mainFrame = document.querySelector(".gallery-main__frame")

        if (mainImage && mainFrame) {
          mainImage.classList.remove("hidden")
          mainFrame.classList.remove("loading")
          mainImage.dispatchEvent(new Event("load"))
        }
      })()
    JS
  end
end
