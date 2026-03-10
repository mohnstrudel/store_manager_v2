# frozen_string_literal: true

module Helpers
  module FileUpload
    # Creates a minimal valid JPEG file for Capybara file uploads in feature specs
    #
    # @param filename [String] The filename to use for the test image
    # @return [void]
    def create_test_image(filename = "test.jpg")
      Rails.root.join("tmp", filename).open("wb") do |f|
        # JPEG SOI (Start of Image) marker + APP0 marker
        f.write("\xFF\xD8\xFF\xE0\x00\x10JFIF")
        # JFIF identifier and version
        f.write("\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00")
        # JPEG EOI (End of Image) marker
        f.write("\xFF\xD9")
      end
    end

    # Removes a test image file created by create_test_image
    #
    # @param filename [String] The filename of the test image to remove
    # @return [void]
    def cleanup_test_image(filename = "test.jpg")
      path = Rails.root.join("tmp", filename)
      File.delete(path) if File.exist?(path)
    end
  end
end
