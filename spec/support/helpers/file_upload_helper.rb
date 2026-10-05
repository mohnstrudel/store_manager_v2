# frozen_string_literal: true

module Helpers
  module FileUpload
    def create_test_image(filename = "test.jpg")
      Rails.root.join("tmp", filename).open("wb") do |f|
        f.write("\xFF\xD8\xFF\xE0\x00\x10JFIF")
        f.write("\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00")
        f.write("\xFF\xD9")
      end
    end

    def cleanup_test_image(filename = "test.jpg")
      path = Rails.root.join("tmp", filename)
      File.delete(path) if File.exist?(path)
    end
  end
end
