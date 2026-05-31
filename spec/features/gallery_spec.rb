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

    expect(page).to have_css(".gallery_nav")
    expect(page).to have_css(".gallery_thumb.active")

    geometry = page.evaluate_script(<<~JS)
      (() => {
        const thumbFrame = document.querySelector(".gallery_thumb__frame")
        const thumbImage = document.querySelector(".gallery_thumb__image")
        const mainFrame = document.querySelector(".gallery_main__frame")
        const mainImage = document.querySelector(".gallery_main__image")

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
      expect(geometry["mainImageHeight"]).to be_within(3.0).of(geometry["mainFrameHeight"])
    end
  end

  # rubocop:todo RSpec/MultipleExpectations
  scenario "tracks the active preview and scrolls it into view while switching images" do
    product = create(:product)
    attach_gallery_images_to(product)

    visit product_path(product)

    expect(page).to have_css(".gallery_nav")

    initial_state = page.evaluate_script(<<~JS)
      (() => {
        const mainImage = document.querySelector(".gallery_main__image")

        return {
          activeThumbSrc: document.querySelector(".gallery_thumb.active img").src,
          src: mainImage.src,
          scrollCalls: window.__galleryScrollCalls || []
        }
      })()
    JS

    page.execute_script(<<~JS)
      (() => {
        window.__galleryScrollCalls = []
        Element.prototype.scrollIntoView = function(options) {
          window.__galleryScrollCalls.push({
            active: this.classList.contains("active"),
            className: this.className,
            options
          })
        }
      })()
    JS

    find(".gallery_btn.right-0").click

    final_state = page.evaluate_script(<<~JS)
      (() => ({
        activeThumbSrc: document.querySelector(".gallery_thumb.active img").src,
        src: document.querySelector(".gallery_main__image").src,
        scrollCalls: window.__galleryScrollCalls
      }))()
    JS

    aggregate_failures do
      expect(final_state["activeThumbSrc"]).not_to eq(initial_state["activeThumbSrc"])
      expect(final_state["src"]).not_to eq(initial_state["src"])
      expect(final_state["scrollCalls"].last["active"]).to eq(true)
      expect(final_state["scrollCalls"].last["options"]).to include(
        "behavior" => "smooth",
        "block" => "nearest",
        "inline" => "start"
      )
    end
  end
  # rubocop:enable RSpec/MultipleExpectations

  # rubocop:todo RSpec/MultipleExpectations
  scenario "keeps a single product image from stretching the layout" do
    page.driver.resize(1440, 1200)

    product = create(:product)
    attach_single_gallery_image_to(product)

    visit product_path(product)

    expect(page).to have_css(".gallery_viewbox")

    geometry = page.evaluate_script(<<~JS)
      (() => {
        const viewbox = document.querySelector(".gallery_viewbox")
        const detailCard = document.querySelector(".cards .card")
        const mainImage = document.querySelector(".gallery_main__image")
        const viewboxRect = viewbox.getBoundingClientRect()

        return {
          detailCardLeft: detailCard.getBoundingClientRect().left,
          viewboxHeight: viewboxRect.height,
          viewboxRatio: viewboxRect.width / viewboxRect.height,
          viewboxRight: viewboxRect.right,
          viewboxWidth: viewboxRect.width,
          mainImageWidth: mainImage.getBoundingClientRect().width,
          mainImageHeight: mainImage.getBoundingClientRect().height
        }
      })()
    JS

    aggregate_failures do
      expect(geometry["viewboxWidth"]).to be_within(1.0).of(3)
      expect(geometry["viewboxHeight"]).to be_within(1.0).of(4)
      expect(geometry["viewboxRatio"]).to be_within(0.05).of(0.75)
      expect(geometry["mainImageWidth"]).to be_within(1.0).of(1)
      expect(geometry["mainImageHeight"]).to be_within(1.0).of(2)
      expect(geometry["detailCardLeft"]).to be > geometry["viewboxRight"]
    end
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

  def attach_single_gallery_image_to(product)
    create_valid_tall_test_png("gallery-1.png")

    attach_image_to(create(:media, :for_product, mediaable: product), "gallery-1.png")
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

  def create_valid_tall_test_png(filename)
    Rails.root.join("tmp", filename).binwrite(Base64.decode64(valid_tall_test_png_base64))
  end

  def valid_test_png_base64
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aW1cAAAAASUVORK5CYII="
  end

  def valid_tall_test_png_base64
    [
      "iVBORw0KGgoAAAANSUhEUgAAAAEAAAACAQAAAACx+ouKAAAAIGNIUk0AAHomAACAhAAA+gAAAIDo",
      "AAB1MAAA6mAAADqYAAAXcJy6UTwAAAACYktHRAAB3YoTpAAAAAd0SU1FB+oFHxMgOvZ5usQAAAAl",
      "dEVYdGRhdGU6Y3JlYXRlADIwMjYtMDUtMzFUMTk6MzI6NTgrMDA6MDBBl2Z8AAAAJXRFWHRkYXRl",
      "Om1vZGlmeQAyMDI2LTA1LTMxVDE5OjMyOjU4KzAwOjAwMMrewAAAACh0RVh0ZGF0ZTp0aW1lc3Rh",
      "bXAAMjAyNi0wNS0zMVQxOTozMjo1OCswMDowMGff/x8AAAAMSURBVAjXY2hgaAAAAgQBARwRMr8A",
      "AAAASUVORK5CYII=",
    ].join
  end

end
