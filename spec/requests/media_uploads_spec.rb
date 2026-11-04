# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Media uploads" do
  before { sign_in_as_admin }

  def minimal_jpeg(filename: "test.jpg")
    Rack::Test::UploadedFile.new(
      StringIO.new("\xFF\xD8\xFF\xE0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00\xFF\xD9"),
      "image/jpeg",
      original_filename: filename
    )
  end

  describe "POST /media/uploads" do
    it "stores the file and returns the signed id of its blob", :aggregate_failures do
      expect {
        post media_uploads_path, params: {file: minimal_jpeg}
      }.to change(ActiveStorage::Blob, :count).by(1)

      expect(response).to have_http_status(:ok)
      signed_id = response.parsed_body["signed_id"]
      expect(signed_id).to be_present
      expect(ActiveStorage::Blob.find_signed(signed_id)).to be_a(ActiveStorage::Blob)
    end

    it "returns 422 without a file", :aggregate_failures do
      expect { post media_uploads_path }.not_to change(ActiveStorage::Blob, :count)

      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
